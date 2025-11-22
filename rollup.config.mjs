import { nodeResolve } from '@rollup/plugin-node-resolve';

const esm = {
  input: 'dist/esm/index.js',
  external: ['@capacitor/core'],
  output: [
    {
      file: 'dist/plugin.js',
      format: 'iife',
      name: 'capacitorZipPlugin',
      globals: {
        '@capacitor/core': 'capacitorExports',
      },
      sourcemap: true,
      inlineDynamicImports: true,
    },
    {
      file: 'dist/plugin.cjs.js',
      format: 'cjs',
      sourcemap: true,
      inlineDynamicImports: true,
    },
  ],
  plugins: [
    nodeResolve({
      browser: true,
    }),
  ],
};

export default [esm];