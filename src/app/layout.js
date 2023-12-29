import { Web3Modal } from "@/context/Web3Modal";
import "./globals.css";
import { Inter } from "next/font/google";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Passport NFT",
  description: "Passport NFT minting and managing website",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Web3Modal>
          {children}
        </Web3Modal>
      </body>
    </html>
  );
}
