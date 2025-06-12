import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Download, Calendar, TrendingUp, Users, DollarSign } from "lucide-react";
import type { Payment, Member } from "@shared/schema";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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
    return Array.from(new Set(years)).sort((a, b) => b - a);
  };

  // Filter payments by selected month and year
  const getFilteredPayments = () => {
    return payments.filter(payment => {
      const paymentDate = new Date(payment.paymentDate);
      const paymentYear = paymentDate.getFullYear();
      const paymentMonth = paymentDate.getMonth();
      
      if (selectedYear && selectedYear !== "all" && paymentYear !== parseInt(selectedYear)) return false;
      if (selectedMonth && selectedMonth !== "all" && paymentMonth !== parseInt(selectedMonth)) return false;
      
      return true;
    });
  };

  // Calculate monthly statistics for all members
  const getMonthlyStats = () => {
    const currentDate = new Date();
    const monthlyStats = [];
    
    // Get stats for last 12 months
    for (let i = 11; i >= 0; i--) {
      const targetDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const month = targetDate.getMonth();
      const year = targetDate.getFullYear();
      
      const monthlyPayments = payments.filter(payment => {
        const paymentDate = new Date(payment.paymentDate);
        return paymentDate.getMonth() === month && paymentDate.getFullYear() === year;
      });
      
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
        partialMembers,
        pendingMembers: members.length - paidMembers - partialMembers,
        totalAmount: totalAmount,
        paymentRate: members.length > 0 ? ((paidMembers / members.length) * 100) : 0
      });
    }
    
    return monthlyStats;
  };

  const monthlyStats = getMonthlyStats();

  // Get detailed member payment status for a specific month
  const getMemberPaymentDetails = (month: number, year: number) => {
    const monthlyPayments = payments.filter(payment => {
      const paymentDate = new Date(payment.paymentDate);
      return paymentDate.getMonth() === month && paymentDate.getFullYear() === year;
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

  // State for selected month for member details
  const [selectedMemberDetailsMonth, setSelectedMemberDetailsMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  });

  // Get member details for selected month
  const getSelectedMonthDetails = () => {
    const [year, month] = selectedMemberDetailsMonth.split('-').map(Number);
    return getMemberPaymentDetails(month - 1, year);
  };

  const selectedMonthDetails = getSelectedMonthDetails();

  // Get current month details
  const currentDate = new Date();
  const currentMonthDetails = getMemberPaymentDetails(currentDate.getMonth(), currentDate.getFullYear());

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
    const monthlyData: Record<string, {
      month: string;
      totalAmount: number;
      paymentCount: number;
      uniquePayers: Set<number>;
    }> = {};
    
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
        month: data.month,
        totalAmount: data.totalAmount,
        paymentCount: data.paymentCount,
        uniquePayersCount: data.uniquePayers.size
      }))
      .sort((a, b) => b.month.localeCompare(a.month))
      .slice(0, 6);
  };

  // Get member payment summary
  const getMemberSummary = () => {
    const memberData: Record<number, {
      memberId: number;
      name: string;
      batchNumber: string;
      totalAmount: number;
      paymentCount: number;
      lastPayment: string | null;
    }> = {};
    
    members.forEach(member => {
      memberData[member.id] = {
        memberId: member.id,
        name: member.name,
        batchNumber: member.batchNumber || 'N/A',
        totalAmount: 0,
        paymentCount: 0,
        lastPayment: null
      };
    });

    payments.forEach(payment => {
      if (memberData[payment.memberId]) {
        memberData[payment.memberId].totalAmount += parseFloat(payment.amount);
        memberData[payment.memberId].paymentCount += 1;
        
        const currentLastPayment = memberData[payment.memberId].lastPayment;
        const paymentDate = new Date(payment.paymentDate);
        
        if (!currentLastPayment || paymentDate > new Date(currentLastPayment)) {
          memberData[payment.memberId].lastPayment = paymentDate.toISOString();
        }
      }
    });

    return Object.values(memberData)
      .sort((a, b) => b.totalAmount - a.totalAmount);
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
    try {
      console.log('Financial Reports exportReport function called');
      const doc = new jsPDF();
      const today = new Date();
      const filteredPayments = getFilteredPayments();
      
      // Header
      doc.setFontSize(20);
      doc.setTextColor(40, 40, 40);
      doc.text('Financial Report', 105, 25, { align: 'center' });
      
      // Date and filters
      doc.setFontSize(10);
      doc.setTextColor(100, 100, 100);
      const periodText = selectedYear === "all" ? "All Years" : 
        (selectedMonth === "all" || !selectedMonth) ? selectedYear : 
        `${new Date(0, parseInt(selectedMonth)).toLocaleString('default', { month: 'long' })} ${selectedYear}`;
      doc.text(`Report Period: ${periodText}`, 105, 35, { align: 'center' });
      doc.text(`Generated: ${today.toLocaleDateString()}`, 105, 42, { align: 'center' });
      
      let yPos = 55;
      
      // Summary Statistics
      doc.setFontSize(14);
      doc.setTextColor(40, 40, 40);
      doc.text('Summary Statistics', 20, yPos);
      yPos += 10;
      
      const summaryData = [
        ['Total Payments', monthlyReport.totalPayments.toString()],
        ['Total Amount', `₱${monthlyReport.totalAmount.toLocaleString()}`],
        ['Unique Payers', monthlyReport.uniquePayers.toString()],
        ['Average Payment', `₱${monthlyReport.averagePayment.toLocaleString()}`]
      ];
      
      autoTable(doc, {
        startY: yPos,
        head: [['Metric', 'Value']],
        body: summaryData,
        theme: 'grid',
        styles: { fontSize: 10 },
        headStyles: { fillColor: [41, 128, 185] },
        margin: { left: 20, right: 20 }
      });
      
      yPos = (doc as any).lastAutoTable.finalY + 20;
      
      // Payment Details Table
      if (filteredPayments.length > 0) {
        doc.setFontSize(14);
        doc.text('Payment Details', 20, yPos);
        yPos += 10;
        
        const paymentTableData = filteredPayments.map(payment => {
          const member = members?.find(m => m.id === payment.memberId);
          return [
            member?.name || 'Unknown Member',
            `₱${parseFloat(payment.amount).toLocaleString()}`,
            new Date(payment.paymentDate).toLocaleDateString(),
            payment.notes || 'No notes'
          ];
        });
        
        autoTable(doc, {
          startY: yPos,
          head: [['Member Name', 'Amount', 'Payment Date', 'Notes']],
          body: paymentTableData,
          theme: 'striped',
          styles: { fontSize: 8 },
          headStyles: { fillColor: [41, 128, 185] },
          margin: { left: 20, right: 20 }
        });
        
        yPos = (doc as any).lastAutoTable.finalY + 20;
      }
      
      // Member Summary (Top 10)
      if (memberSummary.length > 0) {
        // Check if we need a new page
        if (yPos > 250) {
          doc.addPage();
          yPos = 30;
        }
        
        doc.setFontSize(14);
        doc.text('Top Contributing Members', 20, yPos);
        yPos += 10;
        
        const memberTableData = memberSummary.slice(0, 10).map((summary) => {
          return [
            summary.name,
            summary.paymentCount.toString(),
            `₱${summary.totalAmount.toLocaleString()}`,
            summary.lastPayment ? new Date(summary.lastPayment).toLocaleDateString() : 'Never'
          ];
        });
        
        autoTable(doc, {
          startY: yPos,
          head: [['Member Name', 'Payments', 'Total Amount', 'Last Payment']],
          body: memberTableData,
          theme: 'striped',
          styles: { fontSize: 8 },
          headStyles: { fillColor: [41, 128, 185] },
          margin: { left: 20, right: 20 }
        });
      }
      
      // Footer
      const pageCount = doc.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(8);
        doc.setTextColor(150, 150, 150);
        doc.text(`Page ${i} of ${pageCount}`, 105, 285, { align: 'center' });
        doc.text('Tau Gamma Phi Rahugan CBC Chapter - Financial Report', 105, 290, { align: 'center' });
      }
      
      // Save the PDF
      const filename = `financial-report-${today.toISOString().split('T')[0]}.pdf`;
      doc.save(filename);
      
      console.log('Financial report PDF generated successfully');
    } catch (error: any) {
      console.error('Financial Reports export error:', error);
      console.error('Error details:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
    }
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
                <SelectItem value="all">All Years</SelectItem>
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
                <SelectItem value="all">All Months</SelectItem>
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
                          ₱{member.totalAmount.toLocaleString()}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-sm text-gray-900">{member.paymentCount}</TableCell>
                      <TableCell className="text-sm text-gray-600">{formatDate(member.lastPayment || '')}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Monthly Payment Statistics */}
      <Card className="mt-6">
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Calendar className="h-5 w-5" />
            <span>Chapter Payment Statistics (12 Months)</span>
          </CardTitle>
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
                {monthlyStats.map((stat) => (
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

      {/* Member Payment Details by Month */}
      <Card className="mt-6">
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle className="flex items-center space-x-2">
              <Users className="h-5 w-5" />
              <span>Member Payment Details</span>
            </CardTitle>
            <Select value={selectedMemberDetailsMonth} onValueChange={setSelectedMemberDetailsMonth}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Select Month" />
              </SelectTrigger>
              <SelectContent>
                {Array.from({ length: 12 }, (_, i) => {
                  const date = new Date();
                  date.setMonth(i);
                  const currentYear = new Date().getFullYear();
                  const monthValue = `${currentYear}-${String(i + 1).padStart(2, '0')}`;
                  return (
                    <SelectItem key={monthValue} value={monthValue}>
                      {date.toLocaleDateString('en-US', { month: 'long' })} {currentYear}
                    </SelectItem>
                  );
                })}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div className="bg-green-50 p-4 rounded-lg">
              <p className="text-sm font-medium text-green-600">Paid</p>
              <p className="text-2xl font-bold text-green-900">
                {selectedMonthDetails.filter(member => member.status === 'paid').length}
              </p>
            </div>
            <div className="bg-red-50 p-4 rounded-lg">
              <p className="text-sm font-medium text-red-600">Unpaid</p>
              <p className="text-2xl font-bold text-red-900">
                {selectedMonthDetails.filter(member => member.status === 'unpaid').length}
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
                {selectedMonthDetails
                  .sort((a, b) => {
                    // Sort by status: paid first, then unpaid
                    const statusOrder = { paid: 0, unpaid: 1 } as const;
                    const statusA = statusOrder[a.status as keyof typeof statusOrder] ?? 2;
                    const statusB = statusOrder[b.status as keyof typeof statusOrder] ?? 2;
                    return statusA - statusB || a.name.localeCompare(b.name);
                  })
                  .map((member) => (
                    <TableRow key={member.id}>
                      <TableCell className="font-medium">{member.name}</TableCell>
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
  );
}