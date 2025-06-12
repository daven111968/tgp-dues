import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Users, Check, Clock, AlertTriangle, Plus, Download, UserPlus } from "lucide-react";
import { useState } from "react";
import PaymentModal from "@/components/modals/payment-modal";
import MemberModal from "@/components/modals/member-modal";

interface Stats {
  totalMembers: number;
  paidMembers: number;
  pendingMembers: number;
  overdueMembers: number;
}

interface RecentPayment {
  id: number;
  amount: string;
  createdAt: string;
  memberName: string;
}

export default function Dashboard() {
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [isMemberModalOpen, setIsMemberModalOpen] = useState(false);

  const { data: stats, isLoading: statsLoading } = useQuery<Stats>({
    queryKey: ["/api/stats"],
  });

  const { data: recentPayments = [], isLoading: paymentsLoading } = useQuery<RecentPayment[]>({
    queryKey: ["/api/recent-payments"],
  });

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return "Just now";
    if (diffInHours < 24) return `${diffInHours} hours ago`;
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays === 1) return "1 day ago";
    return `${diffInDays} days ago`;
  };

  const currentMonth = new Date().toLocaleDateString('en-US', { 
    month: 'long', 
    year: 'numeric' 
  });

  if (statsLoading) {
    return (
      <div className="flex-1 overflow-auto p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Chapter Dashboard</h2>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Chapter Dashboard</h2>
        <p className="text-gray-600">Monthly dues management overview for {currentMonth}</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Members</p>
                <p className="text-3xl font-bold text-gray-900">{stats?.totalMembers || 0}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <Users className="text-primary text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Paid This Month</p>
                <p className="text-3xl font-bold text-green-600">{stats?.paidMembers || 0}</p>
              </div>
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <Check className="text-green-600 text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Pending</p>
                <p className="text-3xl font-bold text-yellow-600">{stats?.pendingMembers || 0}</p>
              </div>
              <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                <Clock className="text-yellow-600 text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Overdue</p>
                <p className="text-3xl font-bold text-red-600">{stats?.overdueMembers || 0}</p>
              </div>
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <AlertTriangle className="text-red-600 text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity & Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Recent Payments</CardTitle>
          </CardHeader>
          <CardContent>
            {paymentsLoading ? (
              <p className="text-gray-500">Loading recent payments...</p>
            ) : recentPayments.length === 0 ? (
              <p className="text-gray-500">No recent payments</p>
            ) : (
              <div className="space-y-3">
                {recentPayments.map((payment) => (
                  <div key={payment.id} className="flex items-center justify-between py-3 border-b border-gray-100 last:border-b-0">
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                        <Check className="text-green-600 text-sm" />
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">{payment.memberName}</p>
                        <p className="text-sm text-gray-600">{formatTime(payment.createdAt)}</p>
                      </div>
                    </div>
                    <span className="text-green-600 font-medium">₱{payment.amount}</span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <Button 
              className="w-full flex items-center justify-center space-x-2"
              onClick={() => setIsPaymentModalOpen(true)}
            >
              <Plus className="h-4 w-4" />
              <span>Record New Payment</span>
            </Button>
            
            <Button 
              variant="outline"
              className="w-full flex items-center justify-center space-x-2"
              onClick={() => setIsMemberModalOpen(true)}
            >
              <UserPlus className="h-4 w-4" />
              <span>Add New Member</span>
            </Button>
            
            <Button 
              variant="outline"
              className="w-full flex items-center justify-center space-x-2"
            >
              <Download className="h-4 w-4" />
              <span>Export Monthly Report</span>
            </Button>
          </CardContent>
        </Card>
      </div>

      <PaymentModal 
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
      />

      <MemberModal 
        isOpen={isMemberModalOpen}
        onClose={() => setIsMemberModalOpen(false)}
      />
    </div>
  );
}
