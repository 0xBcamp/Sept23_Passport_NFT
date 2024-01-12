import { Button } from "@/components/ui/button";
import {
  CardTitle,
  CardHeader,
  CardContent,
  Card,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { AvatarImage, AvatarFallback, Avatar } from "@/components/ui/avatar";

export function Passport({}) {
  return (
    <main className="flex flex-col items-center justify-center h-screen p-4 md:p-0 bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200">
      <div className="grid gap-6 grid-cols-1 lg:grid-cols-2 max-w-full">
        <Card className="lg:col-span-1 order-last lg:order-none bg-purple-300 text-black h-auto lg:h-[75vh] lg:w-[40vw]">
          <CardHeader>
            <div className="flex items-center">
              <CardTitle className="text-3xl font-bold">
                Your Passport
              </CardTitle>
              <Badge className="ml-auto bg-blue-200 text-black">
                <TicketIcon className="h-6 w-6 mr-1 text-black" />
                NFT Minted{"\n                          "}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="flex flex-col items-center">
            <Avatar className="h-32 w-32 mb-4">
              <AvatarImage
                alt="User Avatar"
                src="/placeholder.svg?height=128&width=128"
              />
              <AvatarFallback>NA</AvatarFallback>
            </Avatar>
            <h2 className="text-xl font-bold">John Doe</h2>
            <p className="text-gray-500 mb-4">United States</p>
          </CardContent>
        </Card>
        <Card className="lg:col-span-1 order-first lg:order-none bg-purple-300 text-black h-auto lg:h-[75vh] lg:w-[40vw]">
          <CardHeader>
            <CardTitle className="text-3xl font-bold">
              Visited Countries
            </CardTitle>
            <CardDescription>
              Here are the countries you have visited.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ul className="grid grid-cols-3 gap-2">
              <li className="text-black rounded-md border border-gray-200 p-2 bg-red-200">
                Japan
              </li>
            </ul>
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
