import { useConnection, useWallet } from '@solana/wallet-adapter-react';
import { PublicKey } from '@solana/web3.js';

export const useTest-engineProgram = () => {
  const { connection } = useConnection();
  const { publicKey } = useWallet();

  return {
    // Implementation will be added
  };
};
