@kwdef struct SimulatorAtmosphereConfig

    # Number of levels for the meteorological profiles
    N_met_level::Integer

    # Numer of levels for the RT
    N_RT_level::Integer

    # List of elements (gases, aerosols, scattering, thermal stuff..)
    elements::Vector{RE.AbstractAtmosphereElement}

    # Units for atmosphere
    pressure_unit::Unitful.PressureUnits=u"Pa"
    met_pressure_unit::Unitful.PressureUnits=u"Pa"
    temperature_unit::Unitful.TemperatureUnits=u"K"
    specific_humidity_unit::Unitful.DimensionlessUnits=u"kg/kg"
    altitude_unit::Unitful.LengthUnits=u"m"
    gravity_unit::Unitful.AccelerationUnits=u"m/s^2"

end

@kwdef struct SimulatorSolarConfig

    # Solar model type (e.g. "TSIS")
    solar_model_type::String

    # Path to the solar model file
    solar_model_path::String

    # Calculate solar geometry based on time and location?
    calculate_solar_angles::Bool = true

end

@kwdef struct SimulatorRTConfig

    # One model for each spectral window
    models::Vector{Symbol}
    # A vector of dicts for each spectral window
    model_options::Vector{Union{Vector{T}, T} where {T <: AbstractDict}}
end


@kwdef struct SimulatorGlobalConfig

    # :Wavelength or :Wavenumber
    spectral_unit::Symbol

    # List of spectral windows
    spectral_windows::Vector{RE.SpectralWindow}

    # List of surfaces
    surfaces::Vector{Tuple}

    # Atmosphere configuration
    atmosphere::SimulatorAtmosphereConfig

    # Radiative transfer configuration
    RT::SimulatorRTConfig

    # Solar model configuration
    solar::SimulatorSolarConfig

end


@kwdef struct SimulatorSceneConfig

    # Date
    date::DateTime

    # Solar geometry
    solar_zenith_angle::Float64
    solar_azimuth_angle::Float64

    # Observation geometry
    #viewing_zenith_angle::Float64
    #viewing_azimuth_angle::Float64

    # Location
    loc_longitude::Float64
    loc_latitude::Float64
    loc_altitude::Unitful.Length

    # Surface parameters
    surface_parameters::Vector{Tuple}

    # RT pressure levels
    pressure_levels::Vector{<:Unitful.Pressure}

    # Gas profiles on RT pressure levels
    # (these are hashed by the gas name, rather than gas objects!)
    vmr_levels::Dict{String, Vector{Float64}}

    # Meteorological profiles on MET pressure levels. These must be in meaningful units
    met_pressure_levels::Vector{<:Unitful.Pressure}
    specific_humidity_levels::Vector{Float64}
    temperature_levels::Vector{<:Unitful.Temperature}

end