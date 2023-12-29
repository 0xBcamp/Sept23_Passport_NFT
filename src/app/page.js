import { CreatePassport } from "@/components/CreatePassport";

export default function Home() {
  return (
    <div className="px-16">
      {/* <main className="flex min-h-screen flex-col items-center justify-between p-12"> */}
      <main>
        <CreatePassport />
      </main>
    </div>
  );
}
