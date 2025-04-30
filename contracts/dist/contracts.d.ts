import { type Interface } from "ethers";
export type ContractData = {
    name: string;
    address: string;
    abi: Interface;
};
export declare const contracts: Record<string, ContractData>;
