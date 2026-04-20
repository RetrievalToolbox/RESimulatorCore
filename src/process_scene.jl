function ingest_surface!(
    buffer::EarthAtmosphereBuffer,
    config::SimulatorSceneConfig
    )

    # Loop over spectral windows
    for (i_swin, swin) in enumerate(buffer.spectral_window)

        # How many surface parameters in for this surface?
        N_para = length(config.surface_parameters[i_swin])

        # Grab surface for this object
        surface = buffer.scene.surfaces[swin]

        if surface isa RE.BRDFSurface

            # For now, we can only deal with a single kernel
            if length(surface.kernels) == 1

                kernel = surface.kernels[1]

                if kernel isa RE.LambertianPolynomialKernel

                    if length(kernel.coefficients) < N_para
                        @error "Surface $(surface) does not have enough coefficients to \
                            hold $(N_para) parameters!"
                    end

                    kernel.coefficients[1:N_para] .= config.surface_parameters[i_swin]
                else
                    error("Unsupported BRDF kernel: $(typeof(kernel))")
                end
            else
                error("We only support a single BRDF kernel at the moment!")
            end

        else

            error("Unsupported surface type: $(typeof(surface))")

        end

    end

end


function process_scene!(
    buffer::EarthAtmosphereBuffer,
    config::SimulatorSceneConfig
    )

    #=
        Ingestion phase
        ===============

        Move quantities from the scene config into the buffer.
    =#

    # Create a new location of footprint on the ground
    loc = RE.EarthLocation(
        config.loc_longitude,
        config.loc_latitude,
        config.loc_altitude |> ustrip,
        config.loc_altitude |> unit
    )

    # Move into buffer
    buffer.scene.location = loc

    # Take the surface parameters and move them into the surface objects. We respect the
    # order according to the spectral windows.
    ingest_surface!(buffer, config)


    # Ingest the RT pressure levels
    RE.ingest!(buffer.scene.atmosphere, :pressure_levels, config.pressure_levels)

    # Move the gas profiles into the buffer
    for (gas_name, vmr_levels) in config.vmr_levels
        gas = RE.get_gas_from_name(buffer.scene.atmosphere, gas_name)
        # Make an explicit check here to see if the gas exists
        if isnothing(gas)
            @error "Gas name $(gas) was not found inside the buffer's atmosphere!"
            exit(1)
        end
        @views gas.vmr_levels[:] .= vmr_levels[:]
    end

    # Ingest the meteorological variables
    RE.ingest!(buffer.scene.atmosphere, :met_pressure_levels, config.met_pressure_levels)
    RE.ingest!(buffer.scene.atmosphere, :specific_humidity_levels, config.specific_humidity_levels)
    RE.ingest!(buffer.scene.atmosphere, :temperature_levels, config.temperature_levels)

    #=
        Run the forward model
        =====================
        At this point, ALL required quantities are INSIDE of buffer, or are supplied
        directly as a keyword argument to `forward_model`. `config` is not needed.
        (note we supply a fresh instance of a forward model state vector here..)
    =#

    forward_model(RE.ForwardModelStateVector(); buf=buffer)

    # Hi-res radiances are now stored in buffer.rt.hires_radiances, for each spectral
    # window.

    result = [
        copy(buffer.rt[swin].hires_radiance) for swin in buffer.spectral_window
    ]

    return result

end