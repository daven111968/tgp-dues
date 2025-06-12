import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AuthProvider, useAuth } from "@/lib/auth";
import { OfflineIndicator } from "@/components/ui/offline-indicator";
import Login from "@/pages/login";
import MemberLogin from "@/pages/member-login";
import MemberRegister from "@/pages/member-register";
import Dashboard from "@/pages/dashboard";
import Members from "@/pages/members";
import Payments from "@/pages/payments";
import Activities from "@/pages/activities";
import Reports from "@/pages/reports";
import Settings from "@/pages/settings";
import MemberPortal from "@/pages/member-portal";
import Sidebar from "@/components/layout/sidebar";
import MobileHeader from "@/components/layout/mobile-header";
import NotFound from "@/pages/not-found";

function AuthenticatedApp() {
  const { user } = useAuth();

  if (!user) {
    return (
      <Switch>
        <Route path="/member-login" component={() => <MemberLogin />} />
        <Route path="/member-register" component={() => <MemberRegister />} />
        <Route component={() => <Login />} />
      </Switch>
    );
  }

  // Member-specific view (only access to member portal)
  if (user.accountType === 'member') {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="container mx-auto px-4 py-8">
          <MemberPortal />
        </div>
      </div>
    );
  }

  // Admin view (full dashboard access)
  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <MobileHeader />
        <div className="lg:hidden h-16"></div>
        <div className="p-4 lg:p-0">
          <OfflineIndicator />
        </div>
        <Switch>
          <Route path="/" component={() => <Dashboard />} />
          <Route path="/dashboard" component={() => <Dashboard />} />
          <Route path="/members" component={() => <Members />} />
          <Route path="/payments" component={() => <Payments />} />
          <Route path="/activities" component={() => <Activities />} />
          <Route path="/reports" component={() => <Reports />} />
          <Route path="/settings" component={() => <Settings />} />
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
