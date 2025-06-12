import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import { Plus, Edit, CreditCard, History, Users, Trash2, Eye, ArrowLeft, Mail, Calendar } from "lucide-react";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import PaymentModal from "@/components/modals/payment-modal";
import MemberModal from "@/components/modals/member-modal";
import type { Member, Payment, Contribution } from "@shared/schema";

export default function Members() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [isMemberModalOpen, setIsMemberModalOpen] = useState(false);
  const [isMemberViewOpen, setIsMemberViewOpen] = useState(false);
  const [selectedMember, setSelectedMember] = useState<Member | undefined>();
  const [selectedMemberId, setSelectedMemberId] = useState<number | undefined>();
  const [viewingMember, setViewingMember] = useState<Member | undefined>();

  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: members = [], isLoading } = useQuery<Member[]>({
    queryKey: ["/api/members"],
  });

  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ["/api/payments"],
  });

  const { data: contributions = [] } = useQuery<(Contribution & { memberName: string; activityName: string })[]>({
    queryKey: ["/api/contributions"],
  });

  const deleteMemberMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiRequest('DELETE', `/api/members/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/members"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      toast({
        title: "Success",
        description: "Member deleted successfully!",
      });
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: error.message || "Failed to delete member",
        variant: "destructive",
      });
    },
  });

  // Get member payment status
  const getMemberPaymentStatus = (memberId: number) => {
    const memberPayments = payments.filter(p => p.memberId === memberId);
    const latestPayment = memberPayments
      .sort((a, b) => new Date(b.paymentDate).getTime() - new Date(a.paymentDate).getTime())[0];
    
    if (!latestPayment) return { status: 'overdue', lastPayment: 'Never' };
    
    const now = new Date();
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const paymentDate = new Date(latestPayment.paymentDate);
    
    let status = 'overdue';
    if (paymentDate >= thisMonth) status = 'paid';
    else if (paymentDate >= lastMonth) status = 'pending';
    
    return {
      status,
      lastPayment: paymentDate.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      })
    };
  };

  // Filter members based on search and status
  const filteredMembers = members.filter(member => {
    const matchesSearch = member.name.toLowerCase().includes(search.toLowerCase()) ||
                         member.email.toLowerCase().includes(search.toLowerCase()) ||
                         member.batchNumber.toLowerCase().includes(search.toLowerCase());
    
    if (!matchesSearch) return false;
    
    if (!statusFilter || statusFilter === "all") return true;
    
    const paymentStatus = getMemberPaymentStatus(member.id);
    return paymentStatus.status === statusFilter;
  });

  const handleEditMember = (member: Member) => {
    setSelectedMember(member);
    setIsMemberModalOpen(true);
  };

  const handleRecordPayment = (memberId: number) => {
    setSelectedMemberId(memberId);
    setIsPaymentModalOpen(true);
  };

  const handleDeleteMember = (member: Member) => {
    if (confirm(`Are you sure you want to delete ${member.name}?`)) {
      deleteMemberMutation.mutate(member.id);
    }
  };

  const handleViewMember = (member: Member) => {
    setViewingMember(member);
    setIsMemberViewOpen(true);
  };

  const getMemberPayments = (memberId: number) => {
    return payments.filter(payment => payment.memberId === memberId);
  };

  const getMemberContributions = (memberId: number) => {
    return contributions.filter(contribution => contribution.memberId === memberId);
  };

  const formatDate = (date: string | Date) => {
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const getMemberStats = (memberId: number) => {
    const memberPayments = getMemberPayments(memberId);
    const memberContributions = getMemberContributions(memberId);
    
    const totalPaid = memberPayments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0);
    const totalContributed = memberContributions.reduce((sum, contribution) => sum + parseFloat(contribution.amount), 0);
    
    return {
      totalPaid,
      totalContributed,
      totalPayments: memberPayments.length,
      totalContributions: memberContributions.length,
      lastPayment: memberPayments.length > 0 ? memberPayments[0] : null,
      lastContribution: memberContributions.length > 0 ? memberContributions[0] : null
    };
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'paid':
        return <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Paid</Badge>;
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-800 hover:bg-yellow-100">Pending</Badge>;
      case 'overdue':
        return <Badge className="bg-red-100 text-red-800 hover:bg-red-100">Overdue</Badge>;
      default:
        return <Badge variant="secondary">Unknown</Badge>;
    }
  };

  if (isLoading) {
    return (
      <div className="flex-1 overflow-auto p-6">
        <p>Loading members...</p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-6">
      <div className="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div className="mb-4 sm:mb-0">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Chapter Members</h2>
          <p className="text-gray-600">Manage member information and dues status</p>
        </div>
        <Button 
          onClick={() => {
            setSelectedMember(undefined);
            setIsMemberModalOpen(true);
          }}
          className="flex items-center space-x-2"
        >
          <Plus className="h-4 w-4" />
          <span>Add Member</span>
        </Button>
      </div>

      {/* Search and Filter */}
      <Card className="mb-6">
        <CardContent className="p-6">
          <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
            <div className="flex-1">
              <Input
                type="text"
                placeholder="Search members..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="All Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="paid">Paid</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="overdue">Overdue</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Members Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>Batch Number</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Last Payment</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredMembers.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                      No members found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredMembers.map((member) => {
                    const paymentStatus = getMemberPaymentStatus(member.id);
                    
                    return (
                      <TableRow key={member.id} className="hover:bg-gray-50">
                        <TableCell>
                          <div className="flex items-center">
                            <div className="w-10 h-10 bg-gray-300 rounded-full flex items-center justify-center mr-4">
                              <Users className="h-5 w-5 text-gray-600" />
                            </div>
                            <div>
                              <div className="text-sm font-medium text-gray-900">{member.name}</div>
                              <div className="text-sm text-gray-500">{member.email}</div>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="text-sm text-gray-900">{member.batchNumber}</TableCell>
                        <TableCell>
                          {getStatusBadge(paymentStatus.status)}
                        </TableCell>
                        <TableCell className="text-sm text-gray-900">{paymentStatus.lastPayment}</TableCell>
                        <TableCell>
                          <div className="flex space-x-2">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleViewMember(member)}
                              className="text-blue-600 hover:text-blue-700"
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleEditMember(member)}
                              className="text-primary hover:text-blue-700"
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleRecordPayment(member.id)}
                              className="text-green-600 hover:text-green-700"
                            >
                              <CreditCard className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleDeleteMember(member)}
                              className="text-red-600 hover:text-red-700"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
          
          {/* Pagination Info */}
          <div className="bg-white px-6 py-3 border-t border-gray-200 flex items-center justify-between">
            <div className="text-sm text-gray-700">
              Showing {filteredMembers.length} of {members.length} members
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Member Details Modal */}
      <Dialog open={isMemberViewOpen} onOpenChange={setIsMemberViewOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <Users className="h-5 w-5" />
              <span>Member Details</span>
            </DialogTitle>
          </DialogHeader>
          
          {viewingMember && (
            <div className="space-y-6">
              {/* Member Info */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center space-x-2">
                    <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                      <Users className="h-6 w-6 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="text-xl font-bold">{viewingMember.name}</h3>
                      <p className="text-gray-600">{viewingMember.batchNumber}</p>
                    </div>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <div className="flex items-center space-x-3">
                        <Mail className="h-4 w-4 text-gray-500" />
                        <div>
                          <p className="text-sm font-medium text-gray-500">Email</p>
                          <p className="text-sm text-gray-900">{viewingMember.email}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-3">
                        <Calendar className="h-4 w-4 text-gray-500" />
                        <div>
                          <p className="text-sm font-medium text-gray-500">Member Since</p>
                          <p className="text-sm text-gray-900">{formatDate(viewingMember.joinedAt)}</p>
                        </div>
                      </div>
                    </div>
                    <div className="space-y-4">
                      <div>
                        <p className="text-sm font-medium text-gray-500">Status</p>
                        <div className="mt-1">
                          {getStatusBadge(getMemberPaymentStatus(viewingMember.id).status)}
                        </div>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-500">Member Type</p>
                        <Badge variant="secondary" className="mt-1">
                          {viewingMember.status === 'active' ? 'Active Member' : 'Inactive Member'}
                        </Badge>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Financial Summary */}
              {(() => {
                const stats = getMemberStats(viewingMember.id);
                return (
                  <Card>
                    <CardHeader>
                      <CardTitle>Financial Summary</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div className="bg-green-50 p-4 rounded-lg">
                          <p className="text-sm font-medium text-green-600">Total Dues Paid</p>
                          <p className="text-2xl font-bold text-green-900">₱{stats.totalPaid.toLocaleString()}</p>
                          <p className="text-xs text-green-600">{stats.totalPayments} payments</p>
                        </div>
                        <div className="bg-blue-50 p-4 rounded-lg">
                          <p className="text-sm font-medium text-blue-600">Total Contributions</p>
                          <p className="text-2xl font-bold text-blue-900">₱{stats.totalContributed.toLocaleString()}</p>
                          <p className="text-xs text-blue-600">{stats.totalContributions} contributions</p>
                        </div>
                        <div className="bg-purple-50 p-4 rounded-lg">
                          <p className="text-sm font-medium text-purple-600">Combined Total</p>
                          <p className="text-2xl font-bold text-purple-900">₱{(stats.totalPaid + stats.totalContributed).toLocaleString()}</p>
                          <p className="text-xs text-purple-600">All transactions</p>
                        </div>
                        <div className="bg-gray-50 p-4 rounded-lg">
                          <p className="text-sm font-medium text-gray-600">Last Activity</p>
                          <p className="text-sm font-bold text-gray-900">
                            {stats.lastPayment ? formatDate(stats.lastPayment.paymentDate) : 
                             stats.lastContribution ? formatDate(stats.lastContribution.contributionDate) : 'No activity'}
                          </p>
                          <p className="text-xs text-gray-600">
                            {stats.lastPayment ? 'Payment' : stats.lastContribution ? 'Contribution' : ''}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })()}

              {/* Payment History */}
              {(() => {
                const memberPayments = getMemberPayments(viewingMember.id);
                return (
                  <Card>
                    <CardHeader>
                      <CardTitle>Payment History ({memberPayments.length})</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {memberPayments.length === 0 ? (
                        <div className="text-center py-8 text-gray-500">
                          No payment records found
                        </div>
                      ) : (
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead>Date</TableHead>
                              <TableHead>Amount</TableHead>
                              <TableHead>Period</TableHead>
                              <TableHead>Notes</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {memberPayments.slice(0, 10).map((payment) => (
                              <TableRow key={payment.id}>
                                <TableCell>{formatDate(payment.paymentDate)}</TableCell>
                                <TableCell className="font-medium">₱{parseFloat(payment.amount).toLocaleString()}</TableCell>
                                <TableCell>{payment.paymentPeriod}</TableCell>
                                <TableCell>{payment.notes || '-'}</TableCell>
                              </TableRow>
                            ))}
                          </TableBody>
                        </Table>
                      )}
                    </CardContent>
                  </Card>
                );
              })()}

              {/* Contribution History */}
              {(() => {
                const memberContributions = getMemberContributions(viewingMember.id);
                return (
                  <Card>
                    <CardHeader>
                      <CardTitle>Activity Contributions ({memberContributions.length})</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {memberContributions.length === 0 ? (
                        <div className="text-center py-8 text-gray-500">
                          No contribution records found
                        </div>
                      ) : (
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead>Date</TableHead>
                              <TableHead>Activity</TableHead>
                              <TableHead>Amount</TableHead>
                              <TableHead>Notes</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {memberContributions.slice(0, 10).map((contribution) => (
                              <TableRow key={contribution.id}>
                                <TableCell>{formatDate(contribution.contributionDate)}</TableCell>
                                <TableCell>{contribution.activityName}</TableCell>
                                <TableCell className="font-medium">₱{parseFloat(contribution.amount).toLocaleString()}</TableCell>
                                <TableCell>{contribution.notes || '-'}</TableCell>
                              </TableRow>
                            ))}
                          </TableBody>
                        </Table>
                      )}
                    </CardContent>
                  </Card>
                );
              })()}

              {/* Quick Actions */}
              <Card>
                <CardHeader>
                  <CardTitle>Quick Actions</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-wrap gap-3">
                    <Button
                      onClick={() => {
                        setIsMemberViewOpen(false);
                        handleEditMember(viewingMember);
                      }}
                      variant="outline"
                      className="flex items-center space-x-2"
                    >
                      <Edit className="h-4 w-4" />
                      <span>Edit Member</span>
                    </Button>
                    <Button
                      onClick={() => {
                        setIsMemberViewOpen(false);
                        handleRecordPayment(viewingMember.id);
                      }}
                      className="flex items-center space-x-2"
                    >
                      <CreditCard className="h-4 w-4" />
                      <span>Record Payment</span>
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <PaymentModal 
        isOpen={isPaymentModalOpen}
        onClose={() => {
          setIsPaymentModalOpen(false);
          setSelectedMemberId(undefined);
        }}
        selectedMemberId={selectedMemberId}
      />

      <MemberModal 
        isOpen={isMemberModalOpen}
        onClose={() => {
          setIsMemberModalOpen(false);
          setSelectedMember(undefined);
        }}
        member={selectedMember}
      />
    </div>
  );
}
