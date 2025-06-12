import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Download, Calendar, DollarSign, Trash2 } from "lucide-react";
import PaymentModal from "@/components/modals/payment-modal";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import type { Payment, Member } from "@shared/schema";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

export default function Payments() {
  const [search, setSearch] = useState("");
  const [monthFilter, setMonthFilter] = useState("");
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  
  const { toast } = useToast();
  const queryClient = useQueryClient();

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

  // Get unique months from payments
  const getUniqueMonths = () => {
    const months = payments.map(payment => {
      const date = new Date(payment.paymentDate);
      return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    });
    return Array.from(new Set(months)).sort();
  };

  // Filter payments based on search and month
  const filteredPayments = payments.filter(payment => {
    const memberName = getMemberName(payment.memberId);
    const matchesSearch = memberName.toLowerCase().includes(search.toLowerCase()) ||
                         payment.amount.toString().includes(search.toLowerCase()) ||
                         (payment.notes && payment.notes.toLowerCase().includes(search.toLowerCase()));
    
    if (!matchesSearch) return false;
    
    if (!monthFilter || monthFilter === "all") return true;
    
    const paymentMonth = new Date(payment.paymentDate).toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    return paymentMonth === monthFilter;
  });

  // Calculate total amount for filtered payments
  const totalAmount = filteredPayments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0);

  // Clear all payments mutation
  const clearPaymentsMutation = useMutation({
    mutationFn: async () => {
      const response = await apiRequest('DELETE', '/api/payments/clear');
      return response;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/payments"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      queryClient.invalidateQueries({ queryKey: ["/api/recent-payments"] });
      toast({
        title: "Success",
        description: "All payment records have been cleared",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to clear payment records",
        variant: "destructive",
      });
    },
  });

  // Export monthly report function
  const exportMonthlyReport = () => {
    if (filteredPayments.length === 0) {
      toast({
        title: "No Data",
        description: "No payments to export for the selected period",
        variant: "destructive",
      });
      return;
    }

    // Generate comprehensive report data
    const reportData = {
      reportTitle: `TGP Rahugan CBC Chapter - Monthly Payment Report`,
      period: monthFilter || "All Months",
      generatedDate: new Date().toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }),
      summary: {
        totalPayments: filteredPayments.length,
        totalAmount: totalAmount,
        averagePayment: filteredPayments.length > 0 ? totalAmount / filteredPayments.length : 0,
        uniqueMembers: new Set(filteredPayments.map(p => p.memberId)).size,
        dateRange: {
          earliest: filteredPayments.length > 0 ? 
            filteredPayments.reduce((earliest, p) => 
              new Date(p.paymentDate) < new Date(earliest.paymentDate) ? p : earliest
            ).paymentDate : null,
          latest: filteredPayments.length > 0 ? 
            filteredPayments.reduce((latest, p) => 
              new Date(p.paymentDate) > new Date(latest.paymentDate) ? p : latest
            ).paymentDate : null
        }
      },
      payments: filteredPayments.map(payment => ({
        id: payment.id,
        memberName: getMemberName(payment.memberId),
        amount: parseFloat(payment.amount),
        formattedAmount: `₱${parseFloat(payment.amount).toLocaleString()}`,
        paymentDate: formatDate(payment.paymentDate),
        notes: payment.notes || "No notes",
        recordedAt: formatTime(payment.createdAt),
        monthYear: new Date(payment.paymentDate).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
      }))
    };

    // Create PDF document
    const doc = new jsPDF();
    
    // Set up the document
    doc.setFontSize(18);
    doc.setFont("helvetica", "bold");
    doc.text("TGP Rahugan CBC Chapter", 20, 20);
    
    doc.setFontSize(16);
    doc.text("Monthly Payment Report", 20, 30);
    
    doc.setFontSize(12);
    doc.setFont("helvetica", "normal");
    doc.text(`Period: ${reportData.period}`, 20, 45);
    doc.text(`Generated: ${reportData.generatedDate}`, 20, 52);
    
    // Summary section
    doc.setFontSize(14);
    doc.setFont("helvetica", "bold");
    doc.text("Summary", 20, 70);
    
    doc.setFontSize(11);
    doc.setFont("helvetica", "normal");
    doc.text(`Total Payments: ${reportData.summary.totalPayments}`, 20, 80);
    doc.text(`Total Amount: ₱${reportData.summary.totalAmount.toLocaleString()}`, 20, 87);
    doc.text(`Average Payment: ₱${reportData.summary.averagePayment.toLocaleString()}`, 20, 94);
    doc.text(`Unique Members: ${reportData.summary.uniqueMembers}`, 20, 101);
    
    const earliestDate = reportData.summary.dateRange.earliest ? formatDate(reportData.summary.dateRange.earliest) : 'N/A';
    const latestDate = reportData.summary.dateRange.latest ? formatDate(reportData.summary.dateRange.latest) : 'N/A';
    doc.text(`Date Range: ${earliestDate} to ${latestDate}`, 20, 108);
    
    // Payment details table
    const tableData = reportData.payments.map(payment => [
      payment.id.toString(),
      payment.memberName,
      payment.formattedAmount,
      payment.paymentDate,
      payment.monthYear,
      payment.notes.length > 30 ? payment.notes.substring(0, 30) + "..." : payment.notes
    ]);
    
    autoTable(doc, {
      head: [['ID', 'Member Name', 'Amount', 'Payment Date', 'Month/Year', 'Notes']],
      body: tableData,
      startY: 125,
      styles: {
        fontSize: 9,
        cellPadding: 3,
      },
      headStyles: {
        fillColor: [41, 128, 185],
        textColor: 255,
        fontStyle: 'bold',
      },
      alternateRowStyles: {
        fillColor: [245, 245, 245],
      },
      margin: { top: 125 },
    });
    
    // Save the PDF
    const fileName = `TGP-Payment-Report-${monthFilter ? monthFilter.replace(/\s+/g, '-') : 'All'}-${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);

    toast({
      title: "Success",
      description: "PDF payment report exported successfully",
    });
  };

  const handleClearPayments = () => {
    if (window.confirm("Are you sure you want to clear all payment records? This action cannot be undone.")) {
      clearPaymentsMutation.mutate();
    }
  };

  const formatDate = (date: string | Date) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const formatTime = (date: string | Date) => {
    const dateObj = new Date(date);
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - dateObj.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return "Just now";
    if (diffInHours < 24) return `${diffInHours} hours ago`;
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays === 1) return "1 day ago";
    return `${diffInDays} days ago`;
  };

  if (paymentsLoading) {
    return (
      <div className="flex-1 overflow-auto p-6">
        <p>Loading payments...</p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-4 sm:p-6">
      <div className="mb-4 sm:mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div className="mb-4 sm:mb-0">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-2">Payment Tracking</h2>
          <p className="text-sm sm:text-base text-gray-600">Track and manage member payment history</p>
        </div>
        <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2 w-full sm:w-auto">
          <Button 
            onClick={() => setIsPaymentModalOpen(true)}
            className="flex items-center justify-center space-x-2 touch-friendly"
          >
            <Plus className="h-4 w-4" />
            <span>Record Payment</span>
          </Button>
          <Button 
            onClick={handleClearPayments}
            variant="destructive"
            className="flex items-center justify-center space-x-2 touch-friendly"
            disabled={clearPaymentsMutation.isPending || payments.length === 0}
          >
            <Trash2 className="h-4 w-4" />
            <span>Clear All</span>
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 mb-4 sm:mb-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Payments</p>
                <p className="text-3xl font-bold text-gray-900">{filteredPayments.length}</p>
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
                <p className="text-3xl font-bold text-green-600">₱{totalAmount.toLocaleString()}</p>
              </div>
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <span className="text-green-600 text-xl font-bold">₱</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Average Payment</p>
                <p className="text-3xl font-bold text-gray-900">
                  ₱{filteredPayments.length > 0 ? Math.round(totalAmount / filteredPayments.length) : 0}
                </p>
              </div>
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center">
                <span className="text-gray-600 text-xl font-bold">₱</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filter */}
      <Card className="mb-6">
        <CardContent className="p-6">
          <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
            <div className="flex-1">
              <Input
                type="text"
                placeholder="Search payments..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <Select value={monthFilter} onValueChange={setMonthFilter}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="All Months" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Months</SelectItem>
                {getUniqueMonths().map(month => (
                  <SelectItem key={month} value={month}>{month}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Button 
              onClick={exportMonthlyReport}
              variant="outline" 
              className="flex items-center space-x-2"
              disabled={filteredPayments.length === 0}
            >
              <Download className="h-4 w-4" />
              <span>Export PDF</span>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Payments Table */}
      <Card>
        <CardHeader>
          <CardTitle>Payment History</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="mobile-scroll">
            <Table className="min-w-full">
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Payment Date</TableHead>
                  <TableHead>Time Recorded</TableHead>
                  <TableHead>Notes</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredPayments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                      No payments found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredPayments
                    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
                    .map((payment) => (
                      <TableRow key={payment.id} className="hover:bg-gray-50">
                        <TableCell>
                          <div className="font-medium text-gray-900">{getMemberName(payment.memberId)}</div>
                        </TableCell>
                        <TableCell>
                          <Badge className="bg-green-100 text-green-800 hover:bg-green-100">
                            ₱{payment.amount}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm text-gray-900">
                          {formatDate(payment.paymentDate)}
                        </TableCell>
                        <TableCell className="text-sm text-gray-600">
                          {formatTime(payment.createdAt)}
                        </TableCell>
                        <TableCell className="text-sm text-gray-600">
                          {payment.notes || '-'}
                        </TableCell>
                      </TableRow>
                    ))
                )}
              </TableBody>
            </Table>
          </div>
          
          {/* Pagination Info */}
          <div className="bg-white px-6 py-3 border-t border-gray-200 flex items-center justify-between">
            <div className="text-sm text-gray-700">
              Showing {filteredPayments.length} of {payments.length} payments
            </div>
            <div className="text-sm font-medium text-gray-900">
              Total: ₱{totalAmount.toLocaleString()}
            </div>
          </div>
        </CardContent>
      </Card>

      <PaymentModal 
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
      />
    </div>
  );
}