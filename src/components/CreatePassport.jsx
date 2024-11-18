"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  PASSPORT_RESOLVER_ABI,
  PASSPORT_RESOLVER_CONTRACT_ADDRESS,
} from "@/constants";
import { createImageURI } from "@/lib/createImageURI";
import { NFTStorage } from "nft.storage";
import { useState } from "react";
import { parseEther } from "viem";
import { useAccount, useContractWrite } from "wagmi";

export function CreatePassport() {
  const [name, setName] = useState("");
  const [country, setCountry] = useState("");
  const [dob, setDob] = useState(0);
  const { isDisconnected, isConnected } = useAccount();
  const { isLoading, write } = useContractWrite({
    address: PASSPORT_RESOLVER_CONTRACT_ADDRESS,
    abi: PASSPORT_RESOLVER_ABI,
    functionName: "createPassport",
    async onSettled(data, error) {
      if (data) {
        console.log(`https://sepolia.etherscan.io/tx/${data}`);
      }
      if (error) {
        console.error("error", err);
      }
    },
  });

  const submitHandler = async (e) => {
    e.preventDefault();

    const uri = await uploadImageToIPFS(name, country);
    write({
      args: [name, country, dob, uri],
      value: parseEther("0.08"),
    });
  };

  return (
    <main className="flex flex-col items-center justify-center h-screen p-4 md:p-0 bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200">
      <div className="grid gap-6 grid-cols-1 lg:grid-cols-2 max-w-7xl">
        <Card className="lg:col-span-1 order-last lg:order-none bg-purple-300 text-black">
          <CardHeader>
            <div className="flex items-center">
              <CardTitle className="text-3xl font-bold">
                Your Passport
              </CardTitle>
              <Badge className="ml-auto bg-blue-200 text-black">
                <TicketIcon className="h-6 w-6 mr-1 text-black" />
                NFT Ready{"\n                                        "}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="flex flex-col items-center">
            <Avatar className="h-32 w-32 mb-4">
              <AvatarImage
                alt="User Avatar"
                src="/passportimage.jpg?height=128&width=128"
              />
              <AvatarFallback>NA</AvatarFallback>
            </Avatar>

            {name.length == 0 ? (
              <h2 className="text-xl font-bold">John Doe</h2>
            ) : (
              <h2 className="text-xl font-bold">{name}</h2>
            )}
            {country.length == 0 ? (
              <p className="text-gray-500 mb-4">United States</p>
            ) : (
              <p className="text-gray-500 mb-4">{country}</p>
            )}
            <Button className="mt-4">
              <w3m-button />
            </Button>
          </CardContent>
        </Card>
        <Card className="lg:col-span-1 order-first lg:order-none bg-purple-300 text-black">
          <CardHeader>
            <CardTitle className="text-3xl font-bold">
              Create Digital Passport
            </CardTitle>
            <CardDescription>
              Fill out the form below to create your digital passport. You can
              mint it as an NFT once it's created.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form className="space-y-4">
              <div className="space-y-2">
                <Label className="text-gray-900" htmlFor="name">
                  Full Name
                </Label>
                <Input
                  className="bg-blue-200 text-black"
                  id="name"
                  placeholder="Your Full Name"
                  required
                  onChange={(e) => setName(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-gray-900" htmlFor="country">
                  Country
                </Label>
                <Input
                  className="bg-blue-200 text-black"
                  id="country"
                  placeholder="Your Country"
                  required
                  onChange={(e) => setCountry(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-gray-900" htmlFor="dob">
                  Date of Birth
                </Label>
                <Input
                  className="bg-blue-200 text-black"
                  id="dob"
                  required
                  type="date"
                  onChange={(e) => {
                    const date = e.target.value.toString();
                    const unixTimestamp = Math.floor(
                      new Date(date).getTime() / 1000,
                    );
                    setDob(unixTimestamp);
                  }}
                />
              </div>
              <Button
                className="w-full text-black bg-blue-200"
                type="submit"
                disabled={
                  isDisconnected ||
                  name.length == 0 ||
                  dob == 0 ||
                  country.length == 0 ||
                  isLoading ||
                  !isConnected
                }
                onClick={submitHandler}
              >
                {isLoading ? (
                  <div
                    className="h-4 w-4 rounded-full animate-spin border-[3px] border-solid border-[#FFFFFF] border-r-[#000000]"
                    role="status"
                  />
                ) : (
                  <span>Mint Passport NFT</span>
                )}
                {/* Submit Passport Details */}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}

function TicketIcon(props) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z" />
      <path d="M13 5v2" />
      <path d="M13 17v2" />
      <path d="M13 11v2" />
    </svg>
  );
}

async function uploadImageToIPFS(name, country) {
  const NFT_STORAGE_TOKEN = process.env.NEXT_PUBLIC_NFT_STORAGE_TOKEN;
  const client = new NFTStorage({ token: NFT_STORAGE_TOKEN });

  const svg = createImageURI(name, country);
  const svgFile = new File([svg], "image.svg", { type: "image/svg+xml" });

  const { url } = await client.store({
    name: name,
    image: svgFile,
    description: `${name}'s Passport`,
  });

  return url;
}
