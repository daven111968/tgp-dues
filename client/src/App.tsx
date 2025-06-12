import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AuthProvider, useAuth } from "@/lib/auth";
import Login from "@/pages/login";
import Dashboard from "@/pages/dashboard";
import Members from "@/pages/members";
import Sidebar from "@/components/layout/sidebar";
import MobileHeader from "@/components/layout/mobile-header";
import NotFound from "@/pages/not-found";

function AuthenticatedApp() {
  const { user } = useAuth();

  if (!user) {
    return <Login />;
  }

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <MobileHeader />
        <div className="lg:hidden h-16"></div>
        <Switch>
          <Route path="/" component={() => <Dashboard />} />
          <Route path="/dashboard" component={() => <Dashboard />} />
          <Route path="/members" component={() => <Members />} />
          <Route path="/payments" component={() => <div className="p-6"><h2 className="text-2xl font-bold">Payment Tracking - Coming Soon</h2></div>} />
          <Route path="/reports" component={() => <div className="p-6"><h2 className="text-2xl font-bold">Financial Reports - Coming Soon</h2></div>} />
          <Route path="/settings" component={() => <div className="p-6"><h2 className="text-2xl font-bold">Settings - Coming Soon</h2></div>} />
          <Route component={NotFound} />
        </Switch>
      </div>
    </div>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <TooltipProvider>
          <Toaster />
          <AuthenticatedApp />
        </TooltipProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
