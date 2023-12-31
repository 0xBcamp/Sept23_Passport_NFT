"use client";
/**
 * This code was generated by v0 by Vercel.
 * @see https://v0.dev/t/n9GDuOMn04K
 */
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useEffect, useState } from "react";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import {
  PASSPORT_RESOLVER_ABI,
  PASSPORT_RESOLVER_CONTRACT_ADDRESS,
} from "@/constants";
import { createImageURI } from "@/components/createImageURI";
import { parseEther } from "viem";
import { NFTStorage } from "nft.storage";

export function CreatePassport() {
  const [name, setName] = useState("");
  const [country, setCountry] = useState("");
  const [dob, setDob] = useState(0);
  const { isDisconnected } = useAccount();
  const [hasMinted, setHasMinted] = useState(false);
  const { address, isConnected } = useAccount();

  const { data: passportInfo } = useContractRead({
    address: PASSPORT_RESOLVER_CONTRACT_ADDRESS,
    abi: PASSPORT_RESOLVER_ABI,
    functionName: "getPassport",
    account: address,
    onSuccess() {
      setHasMinted(true);
    },
    onError(err) {
      console.error("Error", err);
      setHasMinted(false);
    },
  });

  const { isLoading, write } = useContractWrite({
    address: PASSPORT_RESOLVER_CONTRACT_ADDRESS,
    abi: PASSPORT_RESOLVER_ABI,
    functionName: "createPassport",
    onSuccess(data) {
      console.log(`https://sepolia.etherscan.io/tx/${data}`);
      setHasMinted(true);
    },
    onError(err) {
      console.error("error", err);
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

  useEffect(() => {
    if (!passportInfo) {
      setHasMinted(false);
    } else {
      setHasMinted(true);
    }
  }, [passportInfo]);

  return (
    (
      <main className="flex flex-col items-center justify-center h-screen p-4 md:p-0">
        <div className="grid gap-6 grid-cols-1 lg:grid-cols-2 max-w-7xl">
          <Card className="lg:col-span-1">
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
                  <Label htmlFor="name">Full Name</Label>
                  <Input
                    id="name"
                    placeholder="Your Full Name"
                    required
                    onChange={(e) => setName(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="country">Country</Label>
                  <Input
                    id="country"
                    placeholder="Your Country"
                    required
                    onChange={(e) => setCountry(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="dob">Date of Birth</Label>
                  <Input
                    id="dob"
                    required
                    type="date"
                    onChange={(e) => {
                      const date = e.target.value.toString();
                      const timestamp = Math.floor(
                        new Date(date).getTime() / 1000,
                      );
                      setDob(timestamp);
                    }}
                  />
                </div>
                <Button
                  className="w-full bg-black text-white"
                  disabled={isDisconnected || hasMinted || name.length == 0 ||
                    dob == 0 || country.length == 0 || isLoading ||
                    !isConnected}
                  type="submit"
                  onClick={submitHandler}
                >
                  {isLoading &&
                    (
                      <div
                        className="h-4 w-4 rounded-full animate-spin border-[3px] border-solid border-[#FFFFFF] border-r-[#cce0ff]"
                        role="status"
                      />
                    )}
                  Mint Passport NFT
                </Button>
              </form>
            </CardContent>
          </Card>
          <Card className="lg:col-span-1">
            <CardHeader>
              <div className="flex items-center">
                <CardTitle className="text-3xl font-bold">
                  Your Passport
                </CardTitle>
                <Badge className="ml-auto">
                  <TicketIcon className="h-6 w-6 mr-1" />
                  NFT Ready{"\n                          "}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="flex flex-col items-center">
              <Avatar className="h-36 w-36 mb-4">
                <AvatarImage
                  alt="User Avatar"
                  src="/passportimage.jpg?height=128&width=128"
                />
                <AvatarFallback>NA</AvatarFallback>
              </Avatar>
              {name.length == 0
                ? <h2 className="text-xl font-bold">John Doe</h2>
                : <h2 className="text-xl font-bold">{name}</h2>}
              {country.length == 0
                ? <p className="text-gray-500 mb-4">United States</p>
                : <p className="text-gray-500 mb-4">{country}</p>}
              <Button className="mt-4">
                <w3m-button />
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
    )
  );
}

function TicketIcon(props) {
  return (
    (
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
    )
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
    description: `Passport NFT for ${name}`,
  });

  return url;
}
