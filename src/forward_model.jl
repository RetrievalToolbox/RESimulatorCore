function forward_model(
    SV::RE.AbstractStateVector;
    buf::RE.EarthAtmosphereBuffer,
    solar_doppler_factor=0.0,
    solar_distance=1.0
)

    #=
        Solar model
        ===========
    =#

    for swin in keys(buf.rt)

        rt = buf.rt[swin]

        RE.calculate_solar_irradiance!(
            rt,
            swin,
            rt.solar_model,
            doppler_factor=solar_doppler_factor
        )

        # Scale solar irradiance according to relative solar distance
        @views rt.hires_solar.I[:] /= (solar_distance^2)

    end


    # Calculate altitude and gravity from scene variables
    RE.calculate_altitude_and_gravity!(buf.scene)

    #=
        Optical properties
        ==================
    =#

    RE.calculate_earth_optical_properties!(buf, SV, N_sublayer=2)


    #=
        Perform radiative transfer calculations
        =======================================
    =#

    for rt in values(buf.rt)
        RE.calculate_radiances_and_jacobians!(rt)
    end

    # All OK - return
    return true

end