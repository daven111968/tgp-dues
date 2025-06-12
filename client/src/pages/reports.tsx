import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Download, Calendar, TrendingUp, Users, DollarSign } from "lucide-react";
import type { Payment, Member } from "@shared/schema";

export default function Reports() {
  const [selectedMonth, setSelectedMonth] = useState("");
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear().toString());

  const { data: payments = [], isLoading: paymentsLoading } = useQuery<Payment[]>({
    queryKey: ["/api/payments"],
  });

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ["/api/members"],
  });

  // Get member name by ID
  const getMemberName = (memberId: number) => {
    const member = members.find(m => m.id === memberId);
    return member?.name || 'Unknown Member';
  };

  // Get available years from payments
  const getAvailableYears = () => {
    const years = payments.map(payment => new Date(payment.paymentDate).getFullYear());
    return [...new Set(years)].sort((a, b) => b - a);
  };

  // Filter payments by selected month and year
  const getFilteredPayments = () => {
    return payments.filter(payment => {
      const paymentDate = new Date(payment.paymentDate);
      const paymentYear = paymentDate.getFullYear();
      const paymentMonth = paymentDate.getMonth();
      
      if (selectedYear && paymentYear !== parseInt(selectedYear)) return false;
      if (selectedMonth && paymentMonth !== parseInt(selectedMonth)) return false;
      
      return true;
    });
  };

  // Calculate monthly summary
  const getMonthlyReport = () => {
    const filteredPayments = getFilteredPayments();
    const totalAmount = filteredPayments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0);
    const uniquePayers = new Set(filteredPayments.map(p => p.memberId)).size;
    
    return {
      totalPayments: filteredPayments.length,
      totalAmount,
      uniquePayers,
      averagePayment: filteredPayments.length > 0 ? totalAmount / filteredPayments.length : 0
    };
  };

  // Get payment trends by month
  const getPaymentTrends = () => {
    const monthlyData = {};
    
    payments.forEach(payment => {
      const date = new Date(payment.paymentDate);
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = {
          month: date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' }),
          totalAmount: 0,
          paymentCount: 0,
          uniquePayers: new Set()
        };
      }
      
      monthlyData[monthKey].totalAmount += parseFloat(payment.amount);
      monthlyData[monthKey].paymentCount += 1;
      monthlyData[monthKey].uniquePayers.add(payment.memberId);
    });

    return Object.values(monthlyData)
      .map(data => ({
        ...data,
        uniquePayersCount: data.uniquePayers.size
      }))
      .sort((a, b) => b.month.localeCompare(a.month))
      .slice(0, 6);
  };

  // Get member payment summary
  const getMemberSummary = () => {
    const memberData = {};
    
    members.forEach(member => {
      memberData[member.id] = {
        name: member.name,
        batchNumber: member.batchNumber,
        totalPaid: 0,
        paymentCount: 0,
        lastPayment: null
      };
    });

    payments.forEach(payment => {
      if (memberData[payment.memberId]) {
        memberData[payment.memberId].totalPaid += parseFloat(payment.amount);
        memberData[payment.memberId].paymentCount += 1;
        
        const currentLastPayment = memberData[payment.memberId].lastPayment;
        const paymentDate = new Date(payment.paymentDate);
        
        if (!currentLastPayment || paymentDate > new Date(currentLastPayment)) {
          memberData[payment.memberId].lastPayment = payment.paymentDate;
        }
      }
    });

    return Object.values(memberData)
      .sort((a, b) => b.totalPaid - a.totalPaid);
  };

  const monthlyReport = getMonthlyReport();
  const paymentTrends = getPaymentTrends();
  const memberSummary = getMemberSummary();

  const formatDate = (dateString: string) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const exportReport = () => {
    const reportData = {
      summary: monthlyReport,
      trends: paymentTrends,
      memberSummary: memberSummary.slice(0, 10),
      generatedAt: new Date().toISOString()
    };
    
    const dataStr = JSON.stringify(reportData, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `dues-report-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    
    URL.revokeObjectURL(url);
  };

  if (paymentsLoading) {
    return (
      <div className="flex-1 overflow-auto p-6">
        <p>Loading reports...</p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-6">
      <div className="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div className="mb-4 sm:mb-0">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Financial Reports</h2>
          <p className="text-gray-600">Comprehensive analysis of chapter finances</p>
        </div>
        <Button 
          onClick={exportReport}
          className="flex items-center space-x-2"
        >
          <Download className="h-4 w-4" />
          <span>Export Report</span>
        </Button>
      </div>

      {/* Filters */}
      <Card className="mb-6">
        <CardContent className="p-6">
          <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
            <Select value={selectedYear} onValueChange={setSelectedYear}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Select Year" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">All Years</SelectItem>
                {getAvailableYears().map(year => (
                  <SelectItem key={year} value={year.toString()}>{year}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select value={selectedMonth} onValueChange={setSelectedMonth}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Select Month" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">All Months</SelectItem>
                {Array.from({ length: 12 }, (_, i) => (
                  <SelectItem key={i} value={i.toString()}>
                    {new Date(2000, i).toLocaleDateString('en-US', { month: 'long' })}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Payments</p>
                <p className="text-3xl font-bold text-gray-900">{monthlyReport.totalPayments}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <Calendar className="text-primary text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Amount</p>
                <p className="text-3xl font-bold text-green-600">₱{monthlyReport.totalAmount.toLocaleString()}</p>
              </div>
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <DollarSign className="text-green-600 text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Paying Members</p>
                <p className="text-3xl font-bold text-blue-600">{monthlyReport.uniquePayers}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <Users className="text-blue-600 text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Average Payment</p>
                <p className="text-3xl font-bold text-gray-900">₱{Math.round(monthlyReport.averagePayment)}</p>
              </div>
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center">
                <TrendingUp className="text-gray-600 text-xl" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Payment Trends */}
        <Card>
          <CardHeader>
            <CardTitle>Monthly Trends</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {paymentTrends.map((trend, index) => (
                <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">{trend.month}</p>
                    <p className="text-sm text-gray-600">{trend.paymentCount} payments • {trend.uniquePayersCount} members</p>
                  </div>
                  <div className="text-right">
                    <p className="font-bold text-green-600">₱{trend.totalAmount.toLocaleString()}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Top Paying Members */}
        <Card>
          <CardHeader>
            <CardTitle>Member Payment Summary</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Member</TableHead>
                    <TableHead>Total Paid</TableHead>
                    <TableHead>Payments</TableHead>
                    <TableHead>Last Payment</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {memberSummary.slice(0, 10).map((member, index) => (
                    <TableRow key={index} className="hover:bg-gray-50">
                      <TableCell>
                        <div>
                          <div className="font-medium text-gray-900">{member.name}</div>
                          <div className="text-sm text-gray-500">{member.batchNumber}</div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge className="bg-green-100 text-green-800 hover:bg-green-100">
                          ₱{member.totalPaid.toLocaleString()}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-sm text-gray-900">{member.paymentCount}</TableCell>
                      <TableCell className="text-sm text-gray-600">{formatDate(member.lastPayment)}</TableCell>
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