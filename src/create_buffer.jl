include("input_functions.jl")

"""
An RT buffer to be used in cases where no RT buffer is needed.
"""
struct NoRTBuffer <: RE.AbstractRTBuffer end

function create_buffer(
    config::SimulatorGlobalConfig;
    T::DataType=Float64
)

    #=
        Top-level checks
        ================
    =#

    if config.spectral_unit ∉ [:Wavelength, :Wavenumber]
        @error "The input dictionary must have a `spectral_unit` key that is either \
        `:Wavelength`, or `:Wavenumber`"
        return false
    end

    #=
        PRODUCE THE OBJECTS
        ===================
        (offloaded into smaller functions)
    =#

    # Solar model => at the moment a single solar model is used for all spectral windows
    solar_model = create_solar_model(config)

    # Create an empty EarthAtmosphereBuffer, and specify units for atmosphere variables
    atmosphere = RE.create_empty_EarthAtmosphere(
        config.atmosphere.N_RT_level,
        config.atmosphere.N_met_level,
        T;
        config.atmosphere.pressure_unit,
        config.atmosphere.met_pressure_unit,
        config.atmosphere.temperature_unit,
        config.atmosphere.specific_humidity_unit,
        config.atmosphere.altitude_unit,
        config.atmosphere.gravity_unit
    )


    # Add all atmosphere elements into the buffer/atmosphere
    for atm in config.atmosphere.elements
        push!(atmosphere.atm_elements, atm)
    end

    # For forward simulations only, we do not really need an RT buffer, which is the
    # object that is intended to hold the instrument-level radiances. RT buffers should
    # be controlled/used by the various interface modules, not by the core simulator code.
    # However, the buffer creation demands such an object, so we just create a placeholder
    # object of type that is <: AbstractRTBuffer.

    rt_buffer = NoRTBuffer()

    # Similar here, the buffer creation routine wants an InstrumentBuffer object, so we
    # just create an empty one. This buffer is used only when down-sampling to instrument
    # resolution using an ISRF. Instrument-level quantities, however, are not part of
    # the scope of this simulator module. Those should be handled separately by dedicated
    # functions for specific instruments.
    instrument_buffer = RE.InstrumentBuffer(
        Float64[], Float64[], Float64[]
    )

    buffer = RE.EarthAtmosphereBuffer(
        RE.ForwardModelStateVector(), # No state vector needed
        config.spectral_windows,
        config.surfaces,
        atmosphere,
        Dict(swin => solar_model for swin in config.spectral_windows),
        config.RT.models,
        RE.VectorRadiance,
        rt_buffer, # see above
        instrument_buffer, # see above
        config.atmosphere.N_RT_level, # The number of retrieval or RT pressure levels
        config.atmosphere.N_met_level, # The number of meteorological pressure levels
        T # The chosen Float data type (e.g. Float16, Float32, Float64)
    )

    # Add the RT model options into each RT object
    for (i_swin, swin) in enumerate(config.spectral_windows)

        rt = buffer.rt[swin]

        # Add each key/value pair. We cannot just replace the entire dictionary since that
        # field in the type cannot be changed (RT buffers themselves are immutable)
        empty!(rt.model_options)

        # Currently use the same RT options for each window..
        for mo in config.RT.model_options[i_swin]
            push!(rt.model_options, mo)
        end
    end

    return buffer

end