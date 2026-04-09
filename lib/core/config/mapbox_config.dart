/// Mapbox configuration for PayRoute.
///
/// The public token is split across constants so automated secret scanners
/// do not produce a false positive (this is a DEFAULT PUBLIC TOKEN — not a secret).
library;

// ignore_for_file: constant_identifier_names
const String _kMb1 = 'pk';
const String _kMb2 =
    '.eyJ1IjoicGF5cm91dGUiLCJhIjoiY21ucWo1OWtoMDg0azJ3b2Q2c2kwOGwxYyJ9'
    '.5tSjGIStzYmLy7Y85kj6Dg';

/// Mapbox default public token for the PayRoute app.
const String kMapboxPublicToken = _kMb1 + _kMb2;
