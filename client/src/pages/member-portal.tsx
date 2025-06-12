import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Calendar, CreditCard, User, MapPin, Clock, FileText } from "lucide-react";
import { Member, Payment } from "@shared/schema";

export default function MemberPortal() {
  const [batchNumber, setBatchNumber] = useState("");
  const [memberName, setMemberName] = useState("");
  const [searchMode, setSearchMode] = useState<"batch" | "name">("batch");
  const [searchQuery, setSearchQuery] = useState("");

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ['/api/members'],
  });

  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ['/api/payments'],
  });

  const handleSearch = () => {
    if (searchMode === "batch" && batchNumber.trim()) {
      setSearchQuery(batchNumber.trim());
    } else if (searchMode === "name" && memberName.trim()) {
      setSearchQuery(memberName.trim());
    }
  };

  const clearSearch = () => {
    setBatchNumber("");
    setMemberName("");
    setSearchQuery("");
  };

  // Find member based on search
  const foundMember = searchQuery ? members.find(member => {
    if (searchMode === "batch") {
      return member.batchNumber?.toLowerCase() === searchQuery.toLowerCase();
    } else {
      return member.name.toLowerCase().includes(searchQuery.toLowerCase());
    }
  }) : null;

  // Get member's payment history
  const memberPayments = foundMember ? 
    payments.filter(payment => payment.memberId === foundMember.id)
      .sort((a, b) => new Date(b.paymentDate).getTime() - new Date(a.paymentDate).getTime()) 
    : [];

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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Member Portal</h1>
          <p className="text-gray-600">Check your monthly dues status</p>
        </div>
      </div>

      {/* Search Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <User className="h-5 w-5" />
            <span>Find Your Account</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex space-x-4">
            <Button
              variant={searchMode === "batch" ? "default" : "outline"}
              onClick={() => setSearchMode("batch")}
              className="flex-1"
            >
              Search by Batch Number
            </Button>
            <Button
              variant={searchMode === "name" ? "default" : "outline"}
              onClick={() => setSearchMode("name")}
              className="flex-1"
            >
              Search by Name
            </Button>
          </div>

          <div className="space-y-4">
            {searchMode === "batch" ? (
              <div>
                <Label htmlFor="batchNumber">Batch Number</Label>
                <Input
                  id="batchNumber"
                  type="text"
                  value={batchNumber}
                  onChange={(e) => setBatchNumber(e.target.value)}
                  placeholder="Enter your batch number (e.g., Batch-2024)"
                  onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                />
              </div>
            ) : (
              <div>
                <Label htmlFor="memberName">Member Name</Label>
                <Input
                  id="memberName"
                  type="text"
                  value={memberName}
                  onChange={(e) => setMemberName(e.target.value)}
                  placeholder="Enter your full name"
                  onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                />
              </div>
            )}

            <div className="flex space-x-2">
              <Button onClick={handleSearch} className="flex-1">
                Search
              </Button>
              <Button variant="outline" onClick={clearSearch}>
                Clear
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Member Information */}
      {foundMember && (
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
                    <p className="text-lg font-semibold text-gray-900">{foundMember.name}</p>
                    {foundMember.alexisName && (
                      <p className="text-sm text-gray-600">Alexis Name: {foundMember.alexisName}</p>
                    )}
                  </div>
                  
                  <div className="flex items-center space-x-3">
                    <MapPin className="h-4 w-4 text-gray-500" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Address</p>
                      <p className="text-sm text-gray-900">{foundMember.address}</p>
                    </div>
                  </div>

                  {foundMember.batchNumber && (
                    <div>
                      <p className="text-sm font-medium text-gray-500">Batch Information</p>
                      <p className="text-sm text-gray-900">
                        {foundMember.batchNumber}
                        {foundMember.batchName && ` - ${foundMember.batchName}`}
                      </p>
                    </div>
                  )}
                </div>

                <div className="space-y-4">
                  <div>
                    <p className="text-sm font-medium text-gray-500">Member Type</p>
                    <p className="text-sm text-gray-900">
                      {foundMember.memberType === "pure_blooded" ? "Pure Blooded" : "Welcome"}
                    </p>
                  </div>

                  <div className="flex items-center space-x-3">
                    <Calendar className="h-4 w-4 text-gray-500" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Date of Initiation</p>
                      <p className="text-sm text-gray-900">{formatDate(foundMember.initiationDate)}</p>
                    </div>
                  </div>

                  {foundMember.memberType === "welcome" && foundMember.welcomingDate && (
                    <div className="flex items-center space-x-3">
                      <Calendar className="h-4 w-4 text-gray-500" />
                      <div>
                        <p className="text-sm font-medium text-gray-500">Welcoming Date</p>
                        <p className="text-sm text-gray-900">{formatDate(foundMember.welcomingDate)}</p>
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
                const status = getPaymentStatus(foundMember);
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
        </div>
      )}

      {searchQuery && !foundMember && (
        <Card>
          <CardContent className="py-8 text-center">
            <User className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Member Not Found</h3>
            <p className="text-gray-600 mb-4">
              {searchMode === "batch" 
                ? "No member found with that batch number. Please check and try again."
                : "No member found with that name. Please check the spelling and try again."
              }
            </p>
            <Button variant="outline" onClick={clearSearch}>
              Try Again
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}