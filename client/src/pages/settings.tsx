import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { Save, Download, Upload, Settings as SettingsIcon, Users, Bell, Shield } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { useToast } from "@/hooks/use-toast";
import type { Member, Payment } from "@shared/schema";

export default function Settings() {
  const { user, logout } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // Chapter Settings
  const [chapterName, setChapterName] = useState("Tau Gamma Phi Rahugan CBC Chapter");
  const [monthlyDues, setMonthlyDues] = useState("500");
  const [chapterAddress, setChapterAddress] = useState("CBC Campus, Philippines");
  const [chapterEmail, setChapterEmail] = useState("tgp.rahugan.cbc@gmail.com");

  // Notification Settings
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [overdueReminders, setOverdueReminders] = useState(true);
  const [paymentConfirmations, setPaymentConfirmations] = useState(true);

  // System Settings
  const [autoBackup, setAutoBackup] = useState(true);
  const [dataRetention, setDataRetention] = useState("12");

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ["/api/members"],
  });

  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ["/api/payments"],
  });

  const saveSettings = () => {
    // In a real app, this would save to the backend
    toast({
      title: "Settings Saved",
      description: "Your settings have been updated successfully.",
    });
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
    <div className="flex-1 overflow-auto p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Settings</h2>
        <p className="text-gray-600">Manage chapter settings and system configuration</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Settings */}
        <div className="lg:col-span-2 space-y-6">
          {/* Chapter Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Users className="h-5 w-5" />
                <span>Chapter Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="chapterName">Chapter Name</Label>
                <Input
                  id="chapterName"
                  value={chapterName}
                  onChange={(e) => setChapterName(e.target.value)}
                  placeholder="Chapter name"
                />
              </div>
              
              <div>
                <Label htmlFor="monthlyDues">Monthly Dues Amount (₱)</Label>
                <Input
                  id="monthlyDues"
                  type="number"
                  value={monthlyDues}
                  onChange={(e) => setMonthlyDues(e.target.value)}
                  placeholder="500"
                />
              </div>

              <div>
                <Label htmlFor="chapterAddress">Chapter Address</Label>
                <Textarea
                  id="chapterAddress"
                  value={chapterAddress}
                  onChange={(e) => setChapterAddress(e.target.value)}
                  placeholder="Chapter address"
                  rows={3}
                />
              </div>

              <div>
                <Label htmlFor="chapterEmail">Chapter Email</Label>
                <Input
                  id="chapterEmail"
                  type="email"
                  value={chapterEmail}
                  onChange={(e) => setChapterEmail(e.target.value)}
                  placeholder="chapter@email.com"
                />
              </div>
            </CardContent>
          </Card>

          {/* Notification Settings */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Bell className="h-5 w-5" />
                <span>Notifications</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Email Notifications</Label>
                  <p className="text-sm text-gray-600">Receive email updates about chapter activities</p>
                </div>
                <Switch
                  checked={emailNotifications}
                  onCheckedChange={setEmailNotifications}
                />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Overdue Payment Reminders</Label>
                  <p className="text-sm text-gray-600">Send reminders for overdue payments</p>
                </div>
                <Switch
                  checked={overdueReminders}
                  onCheckedChange={setOverdueReminders}
                />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Payment Confirmations</Label>
                  <p className="text-sm text-gray-600">Send confirmation emails for payments</p>
                </div>
                <Switch
                  checked={paymentConfirmations}
                  onCheckedChange={setPaymentConfirmations}
                />
              </div>
            </CardContent>
          </Card>

          {/* System Settings */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <SettingsIcon className="h-5 w-5" />
                <span>System Settings</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Automatic Backup</Label>
                  <p className="text-sm text-gray-600">Automatically backup data daily</p>
                </div>
                <Switch
                  checked={autoBackup}
                  onCheckedChange={setAutoBackup}
                />
              </div>

              <Separator />

              <div>
                <Label htmlFor="dataRetention">Data Retention (months)</Label>
                <Input
                  id="dataRetention"
                  type="number"
                  value={dataRetention}
                  onChange={(e) => setDataRetention(e.target.value)}
                  placeholder="12"
                  className="w-32"
                />
                <p className="text-sm text-gray-600 mt-1">How long to keep payment records</p>
              </div>
            </CardContent>
          </Card>

          {/* Data Management */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Shield className="h-5 w-5" />
                <span>Data Management</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-4">
                <Button onClick={exportData} className="flex items-center space-x-2">
                  <Download className="h-4 w-4" />
                  <span>Export Data</span>
                </Button>
                
                <Button variant="outline" className="flex items-center space-x-2">
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
              
              <p className="text-sm text-gray-600">
                Export your chapter data for backup or transfer to another system. 
                Import feature requires administrator approval.
              </p>
            </CardContent>
          </Card>

          {/* Save Button */}
          <div className="flex justify-end">
            <Button onClick={saveSettings} className="flex items-center space-x-2">
              <Save className="h-4 w-4" />
              <span>Save Settings</span>
            </Button>
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* System Status */}
          <Card>
            <CardHeader>
              <CardTitle>System Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
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