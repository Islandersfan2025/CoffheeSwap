import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@cofhe/hardhat-plugin";

const PRIVATE_KEY = vars.get("PRIVATE_KEY");
const ARBITRUM_SEPOLIA_RPC_URL = vars.get(
  "ARBITRUM_SEPOLIA_RPC_URL",
  "https://sepolia-rollup.arbitrum.io/rpc"
);

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  cofhe: {
    logMocks: true,
    gasWarning: true,
  },
  networks: {
    "arb-sepolia": {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      chainId: 421614,
      accounts: [""],
    },
  },
};

export default config;
