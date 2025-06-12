import { useState, useEffect } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/lib/auth";
import { queryClient } from "@/lib/queryClient";
import { Edit, Save, Download, Upload, Users, Shield, SettingsIcon } from "lucide-react";
import type { InsertChapterInfo, ChapterInfo, Member, Payment } from "@shared/schema";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

// Account info form schema
const accountInfoSchema = z.object({
  name: z.string().min(1, "Name is required"),
  username: z.string().min(1, "Username is required"),
  position: z.string().min(1, "Position is required"),
});

type AccountInfoFormData = z.infer<typeof accountInfoSchema>;

export default function Settings() {
  const { user, logout } = useAuth();
  const { toast } = useToast();
  const [editingChapter, setEditingChapter] = useState(false);
  const [editingAccount, setEditingAccount] = useState(false);

  // Fetch data
  const { data: chapterInfo, isLoading: chapterLoading } = useQuery<ChapterInfo>({
    queryKey: ["/api/chapter-info"],
    staleTime: 5 * 60 * 1000,
  });

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ["/api/members"],
    staleTime: 5 * 60 * 1000,
  });

  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ["/api/payments"],
    staleTime: 5 * 60 * 1000,
  });

  // Chapter form
  const chapterForm = useForm<InsertChapterInfo>({
    resolver: zodResolver(z.object({
      chapterName: z.string().min(1, "Chapter name is required"),
      chapterAddress: z.string().min(1, "Address is required"),
      contactEmail: z.string().email("Invalid email format"),
      contactPhone: z.string().min(1, "Phone number is required"),
      treasurerName: z.string().min(1, "Treasurer name is required"),
      treasurerEmail: z.string().email("Invalid email format"),
    })),
    defaultValues: {
      chapterName: "",
      chapterAddress: "",
      contactEmail: "",
      contactPhone: "",
      treasurerName: "",
      treasurerEmail: "",
    },
  });

  // Account form
  const accountForm = useForm<AccountInfoFormData>({
    resolver: zodResolver(accountInfoSchema),
    defaultValues: {
      name: "",
      username: "",
      position: "",
    },
  });

  // Update forms when data loads
  useEffect(() => {
    if (chapterInfo) {
      chapterForm.reset({
        chapterName: chapterInfo.chapterName || "",
        chapterAddress: chapterInfo.chapterAddress || "",
        contactEmail: chapterInfo.contactEmail || "",
        contactPhone: chapterInfo.contactPhone || "",
        treasurerName: chapterInfo.treasurerName || "",
        treasurerEmail: chapterInfo.treasurerEmail || "",
      });
    }
  }, [chapterInfo, chapterForm]);

  useEffect(() => {
    if (user) {
      accountForm.reset({
        name: user.name || "",
        username: user.username || "",
        position: user.position || "",
      });
    }
  }, [user, accountForm]);

  // Update chapter info mutation
  const updateChapterMutation = useMutation({
    mutationFn: async (data: InsertChapterInfo) => {
      const response = await fetch("/api/chapter-info", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });
      if (!response.ok) throw new Error('Failed to update chapter info');
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/chapter-info"] });
      setEditingChapter(false);
      toast({
        title: "Success",
        description: "Chapter information updated successfully.",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to update chapter information.",
        variant: "destructive",
      });
    },
  });

  // Update account info mutation
  const updateAccountMutation = useMutation({
    mutationFn: async (data: AccountInfoFormData) => {
      const response = await fetch("/api/users/current", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });
      if (!response.ok) throw new Error('Failed to update account info');
      return response.json();
    },
    onSuccess: (response) => {
      // Update the user context with new data
      const updatedUser = response.user;
      localStorage.setItem('user', JSON.stringify(updatedUser));
      setEditingAccount(false);
      toast({
        title: "Success",
        description: "Account information updated successfully.",
      });
      // Force a page refresh to update the auth context
      window.location.reload();
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to update account information.",
        variant: "destructive",
      });
    },
  });

  // Form submission handlers
  const onSubmitChapter = (data: InsertChapterInfo) => {
    updateChapterMutation.mutate(data);
  };

  const onSubmitAccount = (data: AccountInfoFormData) => {
    updateAccountMutation.mutate(data);
  };

  // Export data functionality as PDF
  const exportData = () => {
    console.log('Settings exportData function called');
    try {
      const doc = new jsPDF();
      const currentDate = new Date().toLocaleDateString();
      
      // Header
      doc.setFontSize(20);
      doc.text('Chapter Data Export Report', 20, 20);
      
      doc.setFontSize(12);
      doc.text(`Export Date: ${currentDate}`, 20, 35);
      doc.text(`${chapterInfo?.chapterName || 'Tau Gamma Phi Chapter'}`, 20, 45);
      
      // Chapter Information
      doc.setFontSize(16);
      doc.text('Chapter Information', 20, 65);
      
      doc.setFontSize(10);
      let yPos = 75;
      doc.text(`Chapter Name: ${chapterInfo?.chapterName || 'Not set'}`, 20, yPos);
      yPos += 8;
      doc.text(`Address: ${chapterInfo?.chapterAddress || 'Not set'}`, 20, yPos);
      yPos += 8;
      doc.text(`Contact Email: ${chapterInfo?.contactEmail || 'Not set'}`, 20, yPos);
      yPos += 8;
      doc.text(`Contact Phone: ${chapterInfo?.contactPhone || 'Not set'}`, 20, yPos);
      yPos += 8;
      doc.text(`Master Keeper of the Scroll: ${chapterInfo?.treasurerName || 'Not set'}`, 20, yPos);
      yPos += 8;
      doc.text(`Master Keeper of the Scroll Email: ${chapterInfo?.treasurerEmail || 'Not set'}`, 20, yPos);
      
      // Members Summary
      yPos += 20;
      doc.setFontSize(16);
      doc.text('Members Summary', 20, yPos);
      
      yPos += 15;
      doc.setFontSize(10);
      doc.text(`Total Members: ${members.length}`, 20, yPos);
      yPos += 8;
      doc.text(`Total Payments: ${payments.length}`, 20, yPos);
      yPos += 8;
      const totalAmount = payments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0);
      doc.text(`Total Amount Collected: ₱${totalAmount.toLocaleString()}`, 20, yPos);
      
      // Members Table
      if (members.length > 0) {
        yPos += 20;
        doc.setFontSize(16);
        doc.text('Members List', 20, yPos);
        
        const memberTableData = members.map(member => [
          member.name,
          member.batchNumber || 'N/A',
          member.email,
          member.status,
          new Date(member.joinedAt).toLocaleDateString()
        ]);
        
        autoTable(doc, {
          startY: yPos + 10,
          head: [['Name', 'Batch Number', 'Email', 'Status', 'Joined Date']],
          body: memberTableData,
          theme: 'striped',
          styles: { fontSize: 8 },
          headStyles: { fillColor: [41, 128, 185] }
        });
        
        yPos = (doc as any).lastAutoTable.finalY + 20;
      }
      
      // Recent Payments Table
      if (payments.length > 0) {
        // Add new page if needed
        if (yPos > 250) {
          doc.addPage();
          yPos = 20;
        }
        
        doc.setFontSize(16);
        doc.text('Recent Payments', 20, yPos);
        
        const recentPayments = payments
          .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
          .slice(0, 20);
        
        const paymentTableData = recentPayments.map(payment => {
          const member = members.find(m => m.id === payment.memberId);
          return [
            member?.name || 'Unknown',
            `₱${parseFloat(payment.amount).toLocaleString()}`,
            new Date(payment.paymentDate).toLocaleDateString(),
            payment.notes || 'No notes'
          ];
        });
        
        autoTable(doc, {
          startY: yPos + 10,
          head: [['Member Name', 'Amount', 'Payment Date', 'Notes']],
          body: paymentTableData,
          theme: 'striped',
          styles: { fontSize: 8 },
          headStyles: { fillColor: [41, 128, 185] }
        });
      }
      
      // Footer
      const pageCount = doc.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(8);
        doc.text(`Page ${i} of ${pageCount}`, doc.internal.pageSize.width - 30, doc.internal.pageSize.height - 10);
      }
      
      // Save the PDF
      doc.save(`tgp-chapter-report-${new Date().toISOString().split('T')[0]}.pdf`);
      
      // Update last backup time
      localStorage.setItem('lastBackup', currentDate);
      
      toast({
        title: "PDF Report Generated",
        description: "Chapter data has been exported as PDF successfully.",
      });
    } catch (error: any) {
      console.error('Export error:', error);
      console.error('Error details:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
      toast({
        title: "Export Error",
        description: `Failed to generate PDF report: ${error.message || 'Unknown error'}`,
        variant: "destructive",
      });
    }
  };

  const handleFileImport = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const importedData = JSON.parse(e.target?.result as string);
        
        // Validate imported data structure
        if (!importedData.members || !importedData.payments) {
          throw new Error('Invalid backup file format');
        }

        toast({
          title: "Import Ready",
          description: "Backup file loaded. Contact system administrator to complete import.",
        });
      } catch (error) {
        toast({
          title: "Import Error",
          description: "Invalid backup file format.",
          variant: "destructive",
        });
      }
    };
    reader.readAsText(file);
  };

  const getSystemStats = () => {
    const totalMembers = members.length;
    const totalPayments = payments.length;
    const totalAmount = payments.reduce((sum, payment) => sum + parseFloat(payment.amount), 0);
    const lastBackup = localStorage.getItem('lastBackup') || 'Never';

    return {
      totalMembers,
      totalPayments,
      totalAmount,
      lastBackup
    };
  };

  const stats = getSystemStats();

  return (
    <div className="flex-1 overflow-auto p-4 sm:p-6">
      <div className="mb-4 sm:mb-6">
        <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-2">Settings</h2>
        <p className="text-sm sm:text-base text-gray-600">Manage chapter settings and account information</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
        {/* Chapter Information */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-lg font-semibold flex items-center">
              <Users className="h-5 w-5 mr-2" />
              Chapter Information
            </CardTitle>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setEditingChapter(!editingChapter)}
              className="touch-friendly"
            >
              <Edit className="h-4 w-4 mr-1" />
              {editingChapter ? "Cancel" : "Edit"}
            </Button>
          </CardHeader>
          <CardContent>
            {chapterLoading ? (
              <div className="space-y-4">
                <div className="h-4 bg-gray-200 rounded animate-pulse"></div>
                <div className="h-4 bg-gray-200 rounded animate-pulse"></div>
                <div className="h-4 bg-gray-200 rounded animate-pulse"></div>
              </div>
            ) : editingChapter ? (
              <Form {...chapterForm}>
                <form onSubmit={chapterForm.handleSubmit(onSubmitChapter)} className="space-y-4">
                  <FormField
                    control={chapterForm.control}
                    name="chapterName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Chapter Name</FormLabel>
                        <FormControl>
                          <Input placeholder="Enter chapter name" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={chapterForm.control}
                    name="chapterAddress"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Chapter Address</FormLabel>
                        <FormControl>
                          <Textarea placeholder="Enter chapter address" rows={3} {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={chapterForm.control}
                    name="contactEmail"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Contact Email</FormLabel>
                        <FormControl>
                          <Input type="email" placeholder="contact@chapter.com" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={chapterForm.control}
                    name="contactPhone"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Contact Phone</FormLabel>
                        <FormControl>
                          <Input placeholder="+63 123 456 7890" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={chapterForm.control}
                    name="treasurerName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Master Keeper of the Scroll Name</FormLabel>
                        <FormControl>
                          <Input placeholder="Enter Master Keeper of the Scroll name" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={chapterForm.control}
                    name="treasurerEmail"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Master Keeper of the Scroll Email</FormLabel>
                        <FormControl>
                          <Input type="email" placeholder="scroll-keeper@chapter.com" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <div className="flex flex-col sm:flex-row justify-end space-y-2 sm:space-y-0 sm:space-x-2">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => setEditingChapter(false)}
                      className="touch-friendly"
                    >
                      Cancel
                    </Button>
                    <Button
                      type="submit"
                      disabled={updateChapterMutation.isPending}
                      className="touch-friendly"
                    >
                      <Save className="h-4 w-4 mr-2" />
                      {updateChapterMutation.isPending ? "Saving..." : "Save Changes"}
                    </Button>
                  </div>
                </form>
              </Form>
            ) : (
              <div className="space-y-4">
                <div>
                  <Label className="text-sm font-medium text-gray-500">Chapter Name</Label>
                  <p className="text-sm text-gray-900">{chapterInfo?.chapterName || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Address</Label>
                  <p className="text-sm text-gray-900">{chapterInfo?.chapterAddress || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Contact Email</Label>
                  <p className="text-sm text-gray-900">{chapterInfo?.contactEmail || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Contact Phone</Label>
                  <p className="text-sm text-gray-900">{chapterInfo?.contactPhone || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Master Keeper of the Scroll</Label>
                  <p className="text-sm text-gray-900">{chapterInfo?.treasurerName || "Not set"}</p>
                  <p className="text-xs text-gray-600">{chapterInfo?.treasurerEmail || ""}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Account Information */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-lg font-semibold flex items-center">
              <Shield className="h-5 w-5 mr-2" />
              Account Information
            </CardTitle>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setEditingAccount(!editingAccount)}
              className="touch-friendly"
            >
              <Edit className="h-4 w-4 mr-1" />
              {editingAccount ? "Cancel" : "Edit"}
            </Button>
          </CardHeader>
          <CardContent>
            {editingAccount ? (
              <Form {...accountForm}>
                <form onSubmit={accountForm.handleSubmit(onSubmitAccount)} className="space-y-4">
                  <FormField
                    control={accountForm.control}
                    name="name"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Full Name</FormLabel>
                        <FormControl>
                          <Input placeholder="Enter your full name" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={accountForm.control}
                    name="username"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Username</FormLabel>
                        <FormControl>
                          <Input placeholder="Enter username" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={accountForm.control}
                    name="position"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Position</FormLabel>
                        <FormControl>
                          <Input placeholder="Enter your position" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <div className="flex flex-col sm:flex-row justify-end space-y-2 sm:space-y-0 sm:space-x-2">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => setEditingAccount(false)}
                      className="touch-friendly"
                    >
                      Cancel
                    </Button>
                    <Button
                      type="submit"
                      disabled={updateAccountMutation.isPending}
                      className="touch-friendly"
                    >
                      <Save className="h-4 w-4 mr-2" />
                      {updateAccountMutation.isPending ? "Saving..." : "Save Changes"}
                    </Button>
                  </div>
                </form>
              </Form>
            ) : (
              <div className="space-y-4">
                <div>
                  <Label className="text-sm font-medium text-gray-500">Full Name</Label>
                  <p className="text-sm text-gray-900">{user?.name || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Username</Label>
                  <p className="text-sm text-gray-900">{user?.username || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Position</Label>
                  <p className="text-sm text-gray-900">{user?.position || "Not set"}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium text-gray-500">Account Type</Label>
                  <Badge variant="secondary">Administrator</Badge>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Data Management */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-lg font-semibold flex items-center">
              <Download className="h-5 w-5 mr-2" />
              Data Management
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div>
                <Label className="text-sm font-medium text-gray-500">Total Members</Label>
                <p className="text-2xl font-bold text-gray-900">{stats.totalMembers}</p>
              </div>
              <div>
                <Label className="text-sm font-medium text-gray-500">Total Payments</Label>
                <p className="text-2xl font-bold text-gray-900">{stats.totalPayments}</p>
              </div>
              <div>
                <Label className="text-sm font-medium text-gray-500">Total Amount</Label>
                <p className="text-2xl font-bold text-green-600">₱{stats.totalAmount.toLocaleString()}</p>
              </div>
              <div>
                <Label className="text-sm font-medium text-gray-500">Last Export</Label>
                <p className="text-sm text-gray-900">{stats.lastBackup}</p>
              </div>
            </div>
            <Separator />
            <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-4">
              <Button onClick={exportData} className="flex items-center justify-center space-x-2 touch-friendly bg-blue-600 hover:bg-blue-700">
                <Download className="h-4 w-4" />
                <span>Export PDF Report (Settings)</span>
              </Button>
              <div className="relative">
                <Button variant="outline" className="flex items-center justify-center space-x-2 touch-friendly">
                  <Upload className="h-4 w-4" />
                  <span>Import Data</span>
                  <input
                    type="file"
                    accept=".json"
                    onChange={handleFileImport}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  />
                </Button>
              </div>
            </div>
            <p className="text-sm text-gray-600">
              Export your chapter data for backup or transfer to another system.
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}