import { Users, BarChart3, CreditCard, Settings, Gauge, Calendar, UserCheck } from "lucide-react";
import { Link, useLocation } from "wouter";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { LogOut } from "lucide-react";

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: Gauge },
  { name: "Members", href: "/members", icon: Users },
  { name: "Payment Tracking", href: "/payments", icon: CreditCard },
  { name: "Activity Contributions", href: "/activities", icon: Calendar },
  { name: "Financial Reports", href: "/reports", icon: BarChart3 },
  { name: "Settings", href: "/settings", icon: Settings },
];

export default function Sidebar() {
  const [location] = useLocation();
  const { user, logout } = useAuth();

  return (
    <div className="bg-white w-64 min-h-screen shadow-lg border-r border-gray-200 hidden lg:block">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
            <Users className="text-white text-lg" />
          </div>
          <div>
            <h1 className="text-lg font-bold text-gray-900">TGP Rahugan CBC</h1>
            <p className="text-sm text-gray-600">Finance Management</p>
          </div>
        </div>
      </div>
      
      <nav className="mt-6">
        {navigation.map((item) => {
          const isActive = location === item.href;
          const Icon = item.icon;
          
          return (
            <Link key={item.name} href={item.href}>
              <a
                className={`flex items-center px-6 py-3 transition-colors ${
                  isActive
                    ? "text-primary bg-blue-50 border-r-2 border-primary"
                    : "text-gray-700 hover:bg-gray-50 hover:text-primary"
                }`}
              >
                <Icon className="mr-3 h-5 w-5" />
                {item.name}
              </a>
            </Link>
          );
        })}
      </nav>
      
      <div className="absolute bottom-0 w-64 p-6 border-t border-gray-200">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
            <Users className="text-gray-600 text-sm" />
          </div>
          <div className="flex-1">
            <p className="text-sm font-medium text-gray-900">{user?.name}</p>
            <p className="text-xs text-gray-600">{user?.position}</p>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={logout}
            className="text-gray-400 hover:text-gray-600 p-1"
          >
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}
