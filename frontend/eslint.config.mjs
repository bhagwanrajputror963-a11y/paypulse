import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";

const eslintConfig = [
  ...nextCoreWebVitals,
  ...nextTypescript,
  {
    ignores: [
      "node_modules/**",
      ".next/**",
      "out/**",
      "build/**",
      "next-env.d.ts",
    ],
  },
  {
    rules: {
      // Standard fetch-on-mount hook idiom (setState inside useEffect); not a
      // React Compiler target for this app, so keep as a warning, not a build-breaker.
      "react-hooks/set-state-in-effect": "warn",
    },
  },
];

export default eslintConfig;
