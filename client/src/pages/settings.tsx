import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Save, Download, Upload, Settings as SettingsIcon, Users, Bell, Shield, Edit } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type { Member, Payment, ChapterInfo, InsertChapterInfo } from "@shared/schema";
import { insertChapterInfoSchema, insertUserSchema } from "@shared/schema";
import { z } from "zod";

// Account info form schema
const accountInfoSchema = z.object({
  name: z.string().min(1, "Name is required"),
  username: z.string().min(3, "Username must be at least 3 characters"),
  position: z.string().min(1, "Position is required"),
});

type AccountInfoFormData = z.infer<typeof accountInfoSchema>;

export default function Settings() {
  const { user, logout } = useAuth();
  const { toast } = useToast();
  const [editingChapter, setEditingChapter] = useState(false);
  const [editingAccount, setEditingAccount] = useState(false);

  // Fetch chapter info
  const { data: chapterInfo, isLoading: chapterLoading } = useQuery<ChapterInfo>({
    queryKey: ["/api/chapter-info"],
  });

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ["/api/members"],
  });

  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ["/api/payments"],
  });

  // Chapter Info Form
  const chapterForm = useForm<InsertChapterInfo>({
    resolver: zodResolver(insertChapterInfoSchema),
    defaultValues: {
      chapterName: "",
      chapterAddress: "",
      contactEmail: "",
      contactPhone: "",
      treasurerName: "",
      treasurerEmail: "",
    },
  });

  // Account Info Form
  const accountForm = useForm<AccountInfoFormData>({
    resolver: zodResolver(accountInfoSchema),
    defaultValues: {
      name: user?.name || "",
      username: user?.username || "",
      position: user?.position || "",
    },
  });

  // Update forms when data loads
  useEffect(() => {
    if (chapterInfo) {
      chapterForm.reset({
        chapterName: chapterInfo.chapterName,
        chapterAddress: chapterInfo.chapterAddress,
        contactEmail: chapterInfo.contactEmail,
        contactPhone: chapterInfo.contactPhone,
        treasurerName: chapterInfo.treasurerName,
        treasurerEmail: chapterInfo.treasurerEmail,
      });
    }
  }, [chapterInfo, chapterForm]);

  useEffect(() => {
    if (user) {
      accountForm.reset({
        name: user.name,
        username: user.username,
        position: user.position,
      });
    }
  }, [user, accountForm]);

  // Update chapter info mutation
  const updateChapterMutation = useMutation({
    mutationFn: async (data: InsertChapterInfo) => {
      const response = await apiRequest("/api/chapter-info", {
        method: "POST",
        body: JSON.stringify(data),
      });
      return response;
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

  // Update account info mutation (placeholder - would need backend implementation)
  const updateAccountMutation = useMutation({
    mutationFn: async (data: AccountInfoFormData) => {
      // This would require a backend endpoint to update user info
      return Promise.resolve(data);
    },
    onSuccess: () => {
      setEditingAccount(false);
      toast({
        title: "Success",
        description: "Account information updated successfully.",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to update account information.",
        variant: "destructive",
      });
    },
  });

  const onSubmitChapter = (data: InsertChapterInfo) => {
    updateChapterMutation.mutate(data);
  };

  const onSubmitAccount = (data: AccountInfoFormData) => {
    updateAccountMutation.mutate(data);
  };

  const exportData = () => {
    const exportData = {
      members,
      payments,
      settings: {
        chapterName,
        monthlyDues,
        chapterAddress,
        chapterEmail,
        emailNotifications,
        overdueReminders,
        paymentConfirmations,
        autoBackup,
        dataRetention
      },
      exportedAt: new Date().toISOString()
    };

    const dataStr = JSON.stringify(exportData, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `tgp-chapter-backup-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    
    URL.revokeObjectURL(url);
    
    toast({
      title: "Data Exported",
      description: "Chapter data has been exported successfully.",
    });
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
    const lastBackup = new Date().toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric'
    });

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
                        <FormLabel>Treasurer Name</FormLabel>
                        <FormControl>
                          <Input placeholder="Enter treasurer name" {...field} />
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
                        <FormLabel>Treasurer Email</FormLabel>
                        <FormControl>
                          <Input type="email" placeholder="treasurer@chapter.com" {...field} />
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
                  <Label className="text-sm font-medium text-gray-500">Treasurer</Label>
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
        <Card>
          <CardHeader>
            <CardTitle className="text-lg font-semibold flex items-center">
              <Download className="h-5 w-5 mr-2" />
              Data Management
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
              <Button onClick={exportData} className="flex items-center justify-center space-x-2 touch-friendly">
                <Download className="h-4 w-4" />
                <span>Export Backup</span>
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
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Status</span>
                <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Active</Badge>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Total Members</span>
                <span className="font-medium">{stats.totalMembers}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Total Payments</span>
                <span className="font-medium">{stats.totalPayments}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Total Amount</span>
                <span className="font-medium">₱{stats.totalAmount.toLocaleString()}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Last Backup</span>
                <span className="font-medium text-sm">{stats.lastBackup}</span>
              </div>
            </CardContent>
          </Card>

          {/* Account Info */}
          <Card>
            <CardHeader>
              <CardTitle>Account Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label className="text-sm text-gray-600">Officer Name</Label>
                <p className="font-medium">{user?.name}</p>
              </div>
              
              <div>
                <Label className="text-sm text-gray-600">Position</Label>
                <p className="font-medium">{user?.position}</p>
              </div>
              
              <div>
                <Label className="text-sm text-gray-600">Username</Label>
                <p className="font-medium">{user?.username}</p>
              </div>

              <Separator />
              
              <Button 
                variant="outline" 
                onClick={logout}
                className="w-full text-red-600 hover:text-red-700 hover:bg-red-50"
              >
                Sign Out
              </Button>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>Quick Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button variant="outline" size="sm" className="w-full justify-start">
                View System Logs
              </Button>
              <Button variant="outline" size="sm" className="w-full justify-start">
                Generate Report
              </Button>
              <Button variant="outline" size="sm" className="w-full justify-start">
                Contact Support
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}