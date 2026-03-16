enum AppEnv {
  dev,
  staging,
  prod,
}

AppEnv appEnvFromString(String value) {
  switch (value.toLowerCase()) {
    case 'dev':
      return AppEnv.dev;
    case 'staging':
      return AppEnv.staging;
    case 'prod':
    default:
      return AppEnv.prod;
  }
}

AppEnv currentAppEnv() {
  const raw = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  return appEnvFromString(raw);
}
