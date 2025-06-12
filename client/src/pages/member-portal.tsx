import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar, CreditCard, User, MapPin, Clock, FileText, LogOut, Activity, Users } from "lucide-react";
import { Member, Payment, Contribution, Activity as ActivityType } from "@shared/schema";
import { useAuth } from "@/lib/auth";

export default function MemberPortal() {
  const { user, logout } = useAuth();

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ['/api/members'],
  });

  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ['/api/payments'],
  });

  const { data: activities = [] } = useQuery<ActivityType[]>({
    queryKey: ['/api/activities'],
  });

  const { data: contributions = [] } = useQuery<Array<Contribution & { memberName: string; activityName: string }>>({
    queryKey: ['/api/contributions'],
  });

  // Find the current logged-in member
  const currentMember = user ? members.find(member => member.id === user.id) : null;

  // Get member's payment history
  const memberPayments = currentMember ? 
    payments.filter(payment => payment.memberId === currentMember.id)
      .sort((a, b) => new Date(b.paymentDate).getTime() - new Date(a.paymentDate).getTime()) 
    : [];

  // Get member's activity contributions
  const memberContributions = currentMember ? 
    contributions.filter(contribution => contribution.memberId === currentMember.id)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    : [];

  // Calculate monthly statistics for all members
  const getMonthlyStats = () => {
    const monthlyStats = [];
    
    // Get available years from payment data
    const paymentYears = payments.map(payment => new Date(payment.paymentDate).getFullYear());
    const yearSet = new Set(paymentYears);
    const uniqueYears: number[] = [];
    yearSet.forEach(year => uniqueYears.push(year));
    uniqueYears.sort((a, b) => a - b);
    
    // If no payments, use current year
    const currentYear = new Date().getFullYear();
    const availableYears = uniqueYears.length > 0 ? uniqueYears : [currentYear];
    
    // Generate stats for all months in all available years
    availableYears.forEach(year => {
      for (let month = 0; month < 12; month++) {
        const targetDate = new Date(year, month, 1);
        
        const monthlyPayments = payments.filter(payment => {
          const paymentDate = new Date(payment.paymentDate);
          return paymentDate.getMonth() === month && paymentDate.getFullYear() === year;
        });
        
        // Only include months that have payments
        if (monthlyPayments.length > 0) {
          // Group payments by member for this month
          const memberPaymentTotals = new Map();
          monthlyPayments.forEach(payment => {
            const current = memberPaymentTotals.get(payment.memberId) || 0;
            memberPaymentTotals.set(payment.memberId, current + parseFloat(payment.amount));
          });
          
          // Count members who paid full amount (≥100)
          const paidMembers = Array.from(memberPaymentTotals.values()).filter(total => total >= 100).length;
          const partialMembers = Array.from(memberPaymentTotals.values()).filter(total => total > 0 && total < 100).length;
          const totalAmount = monthlyPayments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0);
          
          monthlyStats.push({
            month: targetDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
            totalMembers: members.length,
            paidMembers,
            unpaidMembers: members.length - paidMembers - partialMembers,
            paymentRate: members.length > 0 ? Math.round((paidMembers / members.length) * 100) : 0,
            totalAmount,
            partialMembers
          });
        }
      }
    });
    
    return monthlyStats;
  };

  // State for selected month
  const [selectedMemberMonth, setSelectedMemberMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  });

  // Get detailed member payment status for a specific month
  const getMemberPaymentDetailsForMonth = (monthYear: string) => {
    const [year, month] = monthYear.split('-').map(Number);
    
    const monthlyPayments = payments.filter(payment => {
      const paymentDate = new Date(payment.paymentDate);
      return paymentDate.getMonth() === month - 1 && paymentDate.getFullYear() === year;
    });

    // Group payments by member
    const memberPaymentTotals = new Map();
    monthlyPayments.forEach(payment => {
      const current = memberPaymentTotals.get(payment.memberId) || 0;
      memberPaymentTotals.set(payment.memberId, current + parseFloat(payment.amount));
    });

    return members.map(member => {
      const totalPaid = memberPaymentTotals.get(member.id) || 0;
      const status = totalPaid > 0 ? 'paid' : 'unpaid';

      return {
        id: member.id,
        name: member.name,
        totalPaid,
        status
      };
    });
  };

  const selectedMonthMemberDetails = getMemberPaymentDetailsForMonth(selectedMemberMonth);

  // State for payment statistics month selection
  const [selectedPaymentStatMonth, setSelectedPaymentStatMonth] = useState("all");

  // Get all monthly statistics and filter based on selection
  const allMonthlyStats = getMonthlyStats();
  const filteredPaymentStats = selectedPaymentStatMonth === "all" 
    ? allMonthlyStats 
    : allMonthlyStats.filter(stat => {
        const [year, month] = selectedPaymentStatMonth.split('-').map(Number);
        // Parse the stat.month to get the actual month and year
        const statDate = new Date(stat.month + ' 1, ' + year);
        return statDate.getMonth() === month - 1;
      });

  // Calculate payment status
  const getPaymentStatus = (member: Member) => {
    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();
    
    const currentMonthPayments = payments.filter(payment => {
      const paymentDate = new Date(payment.paymentDate);
      return payment.memberId === member.id &&
             paymentDate.getMonth() === currentMonth &&
             paymentDate.getFullYear() === currentYear;
    });

    const totalPaid = currentMonthPayments.reduce((sum, payment) => 
      sum + parseFloat(payment.amount), 0);

    if (totalPaid >= 100) return { status: "paid", amount: totalPaid };
    if (totalPaid > 0) return { status: "partial", amount: totalPaid };
    return { status: "pending", amount: 0 };
  };

  const formatDate = (date: Date | string) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "paid":
        return <Badge className="bg-green-100 text-green-800">Paid</Badge>;
      case "partial":
        return <Badge className="bg-yellow-100 text-yellow-800">Partial</Badge>;
      case "pending":
        return <Badge className="bg-red-100 text-red-800">Pending</Badge>;
      default:
        return <Badge className="bg-gray-100 text-gray-800">Unknown</Badge>;
    }
  };

  if (!currentMember) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Member Portal</h1>
            <p className="text-gray-600">Welcome, {user?.name}</p>
          </div>
          <Button onClick={logout} variant="outline" className="flex items-center space-x-2">
            <LogOut className="h-4 w-4" />
            <span>Sign Out</span>
          </Button>
        </div>
        
        <Card>
          <CardContent className="py-8 text-center">
            <User className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Member Information Not Found</h3>
            <p className="text-gray-600">Please contact your chapter treasurer for assistance.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Member Portal</h1>
          <p className="text-gray-600">Welcome, {currentMember.name}</p>
        </div>
        <Button onClick={logout} variant="outline" className="flex items-center space-x-2">
          <LogOut className="h-4 w-4" />
          <span>Sign Out</span>
        </Button>
      </div>

      {/* Monthly Payment Statistics */}
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle className="flex items-center space-x-2">
              <FileText className="h-5 w-5" />
              <span>Chapter Payment Statistics</span>
            </CardTitle>
            <Select value={selectedPaymentStatMonth} onValueChange={setSelectedPaymentStatMonth}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Select Period" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Months</SelectItem>
                {(() => {
                  // Get available years from payment data
                  const paymentYears = payments.map(payment => new Date(payment.paymentDate).getFullYear());
                  const yearSet = new Set(paymentYears);
                  const uniqueYears: number[] = [];
                  yearSet.forEach(year => uniqueYears.push(year));
                  uniqueYears.sort((a, b) => b - a);
                  
                  const currentYear = new Date().getFullYear();
                  const availableYears = uniqueYears.length > 0 ? uniqueYears : [currentYear];
                  
                  return availableYears.flatMap(year => 
                    Array.from({ length: 12 }, (_, i) => {
                      const date = new Date();
                      date.setMonth(i);
                      const monthValue = `${year}-${String(i + 1).padStart(2, '0')}`;
                      return (
                        <SelectItem key={monthValue} value={monthValue}>
                          {date.toLocaleDateString('en-US', { month: 'long' })} {year}
                        </SelectItem>
                      );
                    })
                  );
                })()}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Month</TableHead>
                  <TableHead className="text-center">Total Members</TableHead>
                  <TableHead className="text-center">Paid</TableHead>
                  <TableHead className="text-center">Unpaid</TableHead>
                  <TableHead className="text-center">Payment Rate</TableHead>
                  <TableHead className="text-right">Total Collected</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredPaymentStats.map((stat) => (
                  <TableRow key={stat.month}>
                    <TableCell className="font-medium">{stat.month}</TableCell>
                    <TableCell className="text-center">{stat.totalMembers}</TableCell>
                    <TableCell className="text-center">
                      <Badge className="bg-green-100 text-green-800">{stat.paidMembers}</Badge>
                    </TableCell>
                    <TableCell className="text-center">
                      {stat.pendingMembers > 0 ? (
                        <Badge className="bg-red-100 text-red-800">{stat.pendingMembers}</Badge>
                      ) : (
                        <span className="text-gray-400">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-center">
                      <span className={`font-medium ${stat.paymentRate >= 80 ? 'text-green-600' : stat.paymentRate >= 60 ? 'text-yellow-600' : 'text-red-600'}`}>
                        {stat.paymentRate.toFixed(1)}%
                      </span>
                    </TableCell>
                    <TableCell className="text-right font-mono">
                      ₱{stat.totalAmount.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Member Information */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <User className="h-5 w-5" />
                <span>Member Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <p className="text-sm font-medium text-gray-500">Full Name</p>
                    <p className="text-lg font-semibold text-gray-900">{currentMember.name}</p>
                    {currentMember.alexisName && (
                      <p className="text-sm text-gray-600">Alexis Name: {currentMember.alexisName}</p>
                    )}
                  </div>
                  
                  <div className="flex items-center space-x-3">
                    <MapPin className="h-4 w-4 text-gray-500" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Address</p>
                      <p className="text-sm text-gray-900">{currentMember.address}</p>
                    </div>
                  </div>

                  {currentMember.batchNumber && (
                    <div>
                      <p className="text-sm font-medium text-gray-500">Batch Information</p>
                      <p className="text-sm text-gray-900">
                        {currentMember.batchNumber}
                        {currentMember.batchName && ` - ${currentMember.batchName}`}
                      </p>
                    </div>
                  )}
                </div>

                <div className="space-y-4">
                  <div>
                    <p className="text-sm font-medium text-gray-500">Member Type</p>
                    <p className="text-sm text-gray-900">
                      {currentMember.memberType === "pure_blooded" ? "Pure Blooded" : "Welcome"}
                    </p>
                  </div>

                  <div className="flex items-center space-x-3">
                    <Calendar className="h-4 w-4 text-gray-500" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Date of Initiation</p>
                      <p className="text-sm text-gray-900">{formatDate(currentMember.initiationDate)}</p>
                    </div>
                  </div>

                  {currentMember.memberType === "welcome" && currentMember.welcomingDate && (
                    <div className="flex items-center space-x-3">
                      <Calendar className="h-4 w-4 text-gray-500" />
                      <div>
                        <p className="text-sm font-medium text-gray-500">Welcoming Date</p>
                        <p className="text-sm text-gray-900">{formatDate(currentMember.welcomingDate)}</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Current Month Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <CreditCard className="h-5 w-5" />
                <span>Current Month Status</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {(() => {
                const status = getPaymentStatus(currentMember);
                const currentMonth = new Date().toLocaleDateString('en-US', { 
                  month: 'long', 
                  year: 'numeric' 
                });
                
                return (
                  <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div>
                      <p className="text-lg font-semibold text-gray-900">{currentMonth}</p>
                      <p className="text-sm text-gray-600">
                        Amount Paid: ₱{status.amount.toFixed(2)} / ₱100.00
                      </p>
                    </div>
                    <div className="text-right">
                      {getStatusBadge(status.status)}
                      {status.status === "pending" && (
                        <p className="text-sm text-red-600 mt-1">₱{(100 - status.amount).toFixed(2)} remaining</p>
                      )}
                      {status.status === "partial" && (
                        <p className="text-sm text-yellow-600 mt-1">₱{(100 - status.amount).toFixed(2)} remaining</p>
                      )}
                    </div>
                  </div>
                );
              })()}
            </CardContent>
          </Card>

          {/* Payment History */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <FileText className="h-5 w-5" />
                <span>Payment History</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {memberPayments.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <Clock className="h-12 w-12 mx-auto mb-4 text-gray-300" />
                  <p>No payment history found</p>
                  <p className="text-sm">Your payments will appear here once recorded</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Date</TableHead>
                        <TableHead>Amount</TableHead>
                        <TableHead>Notes</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {memberPayments.map((payment) => (
                        <TableRow key={payment.id}>
                          <TableCell>{formatDate(payment.paymentDate)}</TableCell>
                          <TableCell className="font-medium">₱{parseFloat(payment.amount).toFixed(2)}</TableCell>
                          <TableCell>{payment.notes || "—"}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Activity Contributions */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Activity className="h-5 w-5" />
                <span>Activity Contributions</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {memberContributions.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <Activity className="h-12 w-12 mx-auto mb-4 text-gray-300" />
                  <p>No contributions found</p>
                  <p className="text-sm">Your activity contributions will appear here</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Activity</TableHead>
                        <TableHead>Amount</TableHead>
                        <TableHead>Date</TableHead>
                        <TableHead>Notes</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {memberContributions.map((contribution) => (
                        <TableRow key={contribution.id}>
                          <TableCell className="font-medium">{contribution.activityName}</TableCell>
                          <TableCell>₱{parseFloat(contribution.amount).toFixed(2)}</TableCell>
                          <TableCell>{formatDate(contribution.createdAt)}</TableCell>
                          <TableCell>{contribution.notes || "—"}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Payment & Contribution Summary */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <FileText className="h-5 w-5" />
                <span>Financial Summary</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-blue-50 p-4 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-blue-600">Total Dues Paid</p>
                      <p className="text-2xl font-bold text-blue-900">
                        ₱{memberPayments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0).toFixed(2)}
                      </p>
                    </div>
                    <CreditCard className="h-8 w-8 text-blue-500" />
                  </div>
                </div>
                
                <div className="bg-green-50 p-4 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-green-600">Total Contributions</p>
                      <p className="text-2xl font-bold text-green-900">
                        ₱{memberContributions.reduce((sum, contribution) => sum + parseFloat(contribution.amount), 0).toFixed(2)}
                      </p>
                    </div>
                    <Activity className="h-8 w-8 text-green-500" />
                  </div>
                </div>
                
                <div className="bg-purple-50 p-4 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-purple-600">Payment Count</p>
                      <p className="text-2xl font-bold text-purple-900">{memberPayments.length}</p>
                      <p className="text-xs text-purple-600">{memberContributions.length} contributions</p>
                    </div>
                    <FileText className="h-8 w-8 text-purple-500" />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Chapter Member Payment Status by Month */}
          <Card>
            <CardHeader>
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <CardTitle className="flex items-center space-x-2">
                  <Users className="h-5 w-5" />
                  <span>Chapter Payment Status</span>
                </CardTitle>
                <Select value={selectedMemberMonth} onValueChange={setSelectedMemberMonth}>
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Select Month" />
                  </SelectTrigger>
                  <SelectContent>
                    {(() => {
                      // Get available years from payment data
                      const paymentYears = payments.map(payment => new Date(payment.paymentDate).getFullYear());
                      const yearSet = new Set(paymentYears);
                      const uniqueYears: number[] = [];
                      yearSet.forEach(year => uniqueYears.push(year));
                      uniqueYears.sort((a, b) => b - a);
                      
                      const currentYear = new Date().getFullYear();
                      const availableYears = uniqueYears.length > 0 ? uniqueYears : [currentYear];
                      
                      return availableYears.flatMap(year => 
                        Array.from({ length: 12 }, (_, i) => {
                          const date = new Date();
                          date.setMonth(i);
                          const monthValue = `${year}-${String(i + 1).padStart(2, '0')}`;
                          return (
                            <SelectItem key={monthValue} value={monthValue}>
                              {date.toLocaleDateString('en-US', { month: 'long' })} {year}
                            </SelectItem>
                          );
                        })
                      );
                    })()}
                  </SelectContent>
                </Select>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                <div className="bg-green-50 p-4 rounded-lg">
                  <p className="text-sm font-medium text-green-600">Paid</p>
                  <p className="text-2xl font-bold text-green-900">
                    {selectedMonthMemberDetails.filter(member => member.status === 'paid').length}
                  </p>
                </div>
                <div className="bg-red-50 p-4 rounded-lg">
                  <p className="text-sm font-medium text-red-600">Unpaid</p>
                  <p className="text-2xl font-bold text-red-900">
                    {selectedMonthMemberDetails.filter(member => member.status === 'unpaid').length}
                  </p>
                </div>
              </div>

              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Member Name</TableHead>
                      <TableHead className="text-center">Status</TableHead>
                      <TableHead className="text-right">Amount Paid</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {selectedMonthMemberDetails
                      .sort((a, b) => {
                        const statusOrder = { paid: 0, unpaid: 1 } as const;
                        const statusA = statusOrder[a.status as keyof typeof statusOrder] ?? 2;
                        const statusB = statusOrder[b.status as keyof typeof statusOrder] ?? 2;
                        return statusA - statusB || a.name.localeCompare(b.name);
                      })
                      .map((member) => (
                        <TableRow key={member.id} className={member.id === currentMember?.id ? 'bg-blue-50' : ''}>
                          <TableCell className="font-medium">
                            {member.name}
                            {member.id === currentMember?.id && (
                              <span className="ml-2 text-xs text-blue-600">(You)</span>
                            )}
                          </TableCell>
                          <TableCell className="text-center">
                            {member.status === 'paid' && (
                              <Badge className="bg-green-100 text-green-800">Paid</Badge>
                            )}
                            {member.status === 'unpaid' && (
                              <Badge className="bg-red-100 text-red-800">Unpaid</Badge>
                            )}
                          </TableCell>
                          <TableCell className="text-right font-mono">
                            ₱{member.totalPaid.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                          </TableCell>
                        </TableRow>
                      ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
      </div>
    </div>
  );
}