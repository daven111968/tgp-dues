import { useState } from "react";
import { Menu, X, Users, LogOut } from "lucide-react";
import { Link, useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth";

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: "fas fa-tachometer-alt" },
  { name: "Members", href: "/members", icon: "fas fa-users" },
  { name: "Payment Tracking", href: "/payments", icon: "fas fa-credit-card" },
  { name: "Financial Reports", href: "/reports", icon: "fas fa-chart-bar" },
  { name: "Settings", href: "/settings", icon: "fas fa-cog" },
];

export default function MobileHeader() {
  const [isOpen, setIsOpen] = useState(false);
  const [location] = useLocation();
  const { user, logout } = useAuth();

  return (
    <>
      <div className="lg:hidden fixed top-0 left-0 right-0 bg-white border-b border-gray-200 z-40">
        <div className="flex items-center justify-between p-4">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsOpen(true)}
            className="text-gray-600 hover:text-gray-900"
          >
            <Menu className="h-6 w-6" />
          </Button>
          <h1 className="text-lg font-bold text-gray-900">TGP Rahugan CBC</h1>
          <div className="w-6"></div>
        </div>
      </div>

      {/* Mobile Sidebar */}
      {isOpen && (
        <div className="lg:hidden fixed inset-0 z-50">
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setIsOpen(false)} />
          <div className="fixed left-0 top-0 bottom-0 w-64 bg-white shadow-lg">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
                    <Users className="text-white text-lg" />
                  </div>
                  <div>
                    <h1 className="text-lg font-bold text-gray-900">TGP Rahugan CBC</h1>
                    <p className="text-sm text-gray-600">Chapter Management</p>
                  </div>
                </div>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setIsOpen(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <X className="h-5 w-5" />
                </Button>
              </div>
            </div>
            
            <nav className="mt-6">
              {navigation.map((item) => {
                const isActive = location === item.href;
                
                return (
                  <Link key={item.name} href={item.href}>
                    <a
                      onClick={() => setIsOpen(false)}
                      className={`flex items-center px-6 py-3 transition-colors ${
                        isActive
                          ? "text-primary bg-blue-50 border-r-2 border-primary"
                          : "text-gray-700 hover:bg-gray-50 hover:text-primary"
                      }`}
                    >
                      <i className={`${item.icon} mr-3`}></i>
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
        </div>
      )}
    </>
  );
}
