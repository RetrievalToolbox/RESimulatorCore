function create_solar_model(config::SimulatorGlobalConfig)

    # Create a TSIS solar model
    if config.solar.solar_model_type == "TSIS"

        solar_model = RE.TSISSolarModel(
            config.solar.solar_model_path;
            spectral_unit=config.spectral_unit
        )

        return solar_model
    end


    @error "Looks like solar model type $(config.solar.solar_model_type) is not yet \
        implemented"
    return false

end