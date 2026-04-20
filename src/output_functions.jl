function unit_str(un::Unitful.Units)

    # First, grab the units as a non-fancy string (no UTF exponents)
    u1 = sprint(show, un, context=:fancy_exponent => false)
    # Now remove all ^
    u2 = replace(u1, "^" => "")

    return u2

end

function write_scenes_into_nc(
    ds::NCDatasets.NCDataset,
    global_config::SimulatorGlobalConfig,
    scene_config::Vector{SimulatorSceneConfig}
)

    # Create the scene group
    grp = defGroup(ds, "Scenes")

    # Necessary dimensions
    defDim(grp, "met_level", global_config.atmosphere.N_met_level)
    defDim(grp, "RT_level", global_config.atmosphere.N_RT_level)
    defDim(grp, "scene", length(scene_config))

    #=
        Variables
    =#

    # Location
    lons = defVar(grp, "longitude", Float64, ("scene",),
        attrib = OrderedDict(
            "units" => "degrees"
        )
    )

    lats = defVar(grp, "latitude", Float64, ("scene",),
        attrib = OrderedDict(
            "units" => "degrees"
        )
    )

    alts = defVar(grp, "altitude", Float64, ("scene",),
        attrib = OrderedDict(
            "units" => unit_str(global_config.atmosphere.altitude_unit)
        )
    )

    # MET profiles
    grp_met = defGroup(grp, "Meteorology")

    met_p = defVar(grp_met, "met_pressure_levels", Float64, ("met_level", "scene",),
        attrib = OrderedDict(
            "units" => unit_str(global_config.atmosphere.met_pressure_unit)
        )
    )
    met_q = defVar(grp_met, "specific_humidity_levels", Float64, ("met_level", "scene",),
        attrib = OrderedDict(
        "units" => unit_str(global_config.atmosphere.specific_humidity_unit)
        )
    )
    met_T = defVar(grp_met, "temperature_levels", Float64, ("met_level", "scene",),
        attrib = OrderedDict(
            "units" => unit_str(global_config.atmosphere.temperature_unit)
        )
    )

    # RT / gas profiles
    grp_atm = defGroup(grp, "Atmosphere")

    p = defVar(grp_atm, "pressure_levels", Float64, ("RT_level", "scene",),
        attrib = OrderedDict(
            "units" => unit_str(global_config.atmosphere.pressure_unit)
        )
    )

    for atm in global_config.atmosphere.elements

        if atm isa RE.GasAbsorber
            if !("Gas" in keys(grp_atm.group))
                # Create gas group if not already there..
                defGroup(grp_atm, "Gas")
            end

            grp_gas = grp_atm.group["Gas"]

            _gas = defVar(grp_gas, "$(atm.gas_name)", Float64, ("RT_level", "scene",),
                attrib = OrderedDict(
                    "units" => unit_str(atm.vmr_unit)
                )
            )

        end

    end


    for (i_scene, scene) in enumerate(scene_config)

        lons[i_scene] = scene.loc_longitude
        lats[i_scene] = scene.loc_latitude
        alts[i_scene] = ustrip(scene.loc_altitude)

        met_p[:, i_scene] = ustrip(scene.met_pressure_levels)
        met_q[:, i_scene] = ustrip(scene.specific_humidity_levels)
        met_T[:, i_scene] = ustrip(scene.temperature_levels)

        p[:, i_scene] = ustrip(scene.pressure_levels)

        for atm in global_config.atmosphere.elements
            if atm isa RE.GasAbsorber
                grp_atm.group["Gas"]["$(atm.gas_name)"][:, i_scene] = ustrip(atm.vmr_levels)
            end
        end


    end



end