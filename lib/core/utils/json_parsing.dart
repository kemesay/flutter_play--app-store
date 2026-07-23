/// Backend DECIMAL/NUMERIC columns (Sequelize + Postgres) are serialized as
/// JSON strings to avoid floating-point precision loss, while INTEGER columns
/// and values computed server-side (e.g. via `Number()`/`Math.round()`)
/// arrive as JSON numbers. The same API field can therefore be a String in
/// one response and a num in another — parse defensively everywhere instead
/// of casting with `as num?`, which throws on a String.
num? asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

double asDouble(dynamic value, [double fallback = 0]) =>
    asNum(value)?.toDouble() ?? fallback;

int asInt(dynamic value, [int fallback = 0]) =>
    asNum(value)?.toInt() ?? fallback;
