import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Plus, Calendar, Target, Users, TrendingUp, Download, Trash2, AlertTriangle } from "lucide-react";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { insertActivitySchema, insertContributionSchema, type Activity, type Contribution, type Member, type InsertActivity, type InsertContribution } from "@shared/schema";

export default function Activities() {
  const [isActivityModalOpen, setIsActivityModalOpen] = useState(false);
  const [isContributionModalOpen, setIsContributionModalOpen] = useState(false);
  const [selectedActivity, setSelectedActivity] = useState<Activity | null>(null);
  
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: activities = [], isLoading: activitiesLoading } = useQuery<Activity[]>({
    queryKey: ["/api/activities"],
  });

  const { data: contributions = [], isLoading: contributionsLoading } = useQuery<(Contribution & { memberName: string; activityName: string })[]>({
    queryKey: ["/api/contributions"],
  });

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ["/api/members"],
  });

  // Activity form
  const activityForm = useForm<InsertActivity>({
    resolver: zodResolver(insertActivitySchema),
    defaultValues: {
      name: "",
      description: "",
      status: "active",
      startDate: new Date(),
      endDate: undefined,
    },
  });

  // Contribution form
  const contributionForm = useForm<InsertContribution>({
    resolver: zodResolver(insertContributionSchema),
    defaultValues: {
      activityId: 0,
      memberId: 0,
      amount: "",
      contributionDate: new Date(),
      notes: "",
    },
  });

  // Create activity mutation
  const createActivityMutation = useMutation({
    mutationFn: async (data: InsertActivity) => {
      return await apiRequest('POST', '/api/activities', data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/activities"] });
      setIsActivityModalOpen(false);
      activityForm.reset();
      toast({
        title: "Success",
        description: "Activity created successfully",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to create activity",
        variant: "destructive",
      });
    },
  });

  // Create contribution mutation
  const createContributionMutation = useMutation({
    mutationFn: async (data: InsertContribution) => {
      return await apiRequest('POST', '/api/contributions', data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/contributions"] });
      queryClient.invalidateQueries({ queryKey: ["/api/activities"] });
      setIsContributionModalOpen(false);
      contributionForm.reset();
      toast({
        title: "Success",
        description: "Contribution recorded successfully",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to record contribution",
        variant: "destructive",
      });
    },
  });

  const onSubmitActivity = (data: InsertActivity) => {
    createActivityMutation.mutate(data);
  };

  const onSubmitContribution = (data: InsertContribution) => {
    createContributionMutation.mutate(data);
  };

  // Delete mutations
  const deleteActivityMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await fetch(`/api/activities/${id}`, {
        method: "DELETE",
      });
      if (!response.ok) throw new Error('Failed to delete activity');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/activities"] });
      queryClient.invalidateQueries({ queryKey: ["/api/contributions"] });
      toast({
        title: "Success",
        description: "Activity deleted successfully",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to delete activity",
        variant: "destructive",
      });
    },
  });

  const deleteContributionMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await fetch(`/api/contributions/${id}`, {
        method: "DELETE",
      });
      if (!response.ok) throw new Error('Failed to delete contribution');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/contributions"] });
      queryClient.invalidateQueries({ queryKey: ["/api/activities"] });
      toast({
        title: "Success",
        description: "Contribution deleted successfully",
      });
    },
    onError: () => {
      toast({
        title: "Error",
        description: "Failed to delete contribution",
        variant: "destructive",
      });
    },
  });

  const formatDate = (date: string | Date) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const getProgressPercentage = (current: string, target: string) => {
    const currentAmount = parseFloat(current);
    const targetAmount = parseFloat(target);
    return targetAmount > 0 ? Math.min((currentAmount / targetAmount) * 100, 100) : 0;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'completed': return 'bg-blue-100 text-blue-800';
      case 'cancelled': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleAddContribution = (activity: Activity) => {
    setSelectedActivity(activity);
    contributionForm.setValue('activityId', activity.id);
    setIsContributionModalOpen(true);
  };

  const exportActivitiesReport = () => {
    try {
      console.log('Activities export function called');
      const doc = new jsPDF();
      const today = new Date();
      
      // Header
      doc.setFontSize(20);
      doc.setTextColor(40, 40, 40);
      doc.text('Activities & Contributions Report', 105, 25, { align: 'center' });
      
      // Date
      doc.setFontSize(10);
      doc.setTextColor(100, 100, 100);
      doc.text(`Generated: ${today.toLocaleDateString()}`, 105, 35, { align: 'center' });
      
      let yPos = 50;
      
      // Summary Statistics
      doc.setFontSize(14);
      doc.setTextColor(40, 40, 40);
      doc.text('Summary Statistics', 20, yPos);
      yPos += 10;
      
      const totalRaised = activities.reduce((sum, a) => sum + parseFloat(a.currentAmount), 0);
      const contributors = new Set(contributions.map(c => c.memberId)).size;
      
      const summaryData = [
        ['Total Activities', activities.length.toString()],
        ['Total Raised', `₱${totalRaised.toLocaleString()}`],
        ['Total Contributors', contributors.toString()],
        ['Total Contributions', contributions.length.toString()]
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
      
      // Activities Table
      if (activities.length > 0) {
        doc.setFontSize(14);
        doc.text('Activities Details', 20, yPos);
        yPos += 10;
        
        const activitiesData = activities.map(activity => {
          return [
            activity.name,
            activity.status.charAt(0).toUpperCase() + activity.status.slice(1),
            `₱${parseFloat(activity.currentAmount).toLocaleString()}`,
            formatDate(activity.createdAt)
          ];
        });
        
        autoTable(doc, {
          startY: yPos,
          head: [['Activity Name', 'Status', 'Total Raised', 'Created']],
          body: activitiesData,
          theme: 'striped',
          styles: { fontSize: 8 },
          headStyles: { fillColor: [41, 128, 185] },
          margin: { left: 20, right: 20 }
        });
        
        yPos = (doc as any).lastAutoTable.finalY + 20;
      }
      
      // Contributions Table
      if (contributions.length > 0) {
        // Check if we need a new page
        if (yPos > 250) {
          doc.addPage();
          yPos = 30;
        }
        
        doc.setFontSize(14);
        doc.text('Contributions Details', 20, yPos);
        yPos += 10;
        
        const contributionsData = contributions.map(contribution => {
          const member = members?.find(m => m.id === contribution.memberId);
          const activity = activities.find(a => a.id === contribution.activityId);
          return [
            member?.name || 'Unknown Member',
            activity?.name || 'Unknown Activity',
            `₱${parseFloat(contribution.amount).toLocaleString()}`,
            formatDate(contribution.createdAt),
            contribution.notes || 'No notes'
          ];
        });
        
        autoTable(doc, {
          startY: yPos,
          head: [['Member Name', 'Activity', 'Amount', 'Date', 'Notes']],
          body: contributionsData,
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
        doc.text('Tau Gamma Phi Rahugan CBC Chapter - Activities Report', 105, 290, { align: 'center' });
      }
      
      // Save the PDF
      const filename = `activities-report-${today.toISOString().split('T')[0]}.pdf`;
      doc.save(filename);
      
      console.log('Activities report PDF generated successfully');
    } catch (error: any) {
      console.error('Activities export error:', error);
      toast({
        title: "Export Error",
        description: `Failed to generate PDF report: ${error.message || 'Unknown error'}`,
        variant: "destructive",
      });
    }
  };

  return (
    <div className="flex-1 overflow-auto p-4 sm:p-6">
      <div className="mb-4 sm:mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div className="mb-4 sm:mb-0">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-2">Activity Contributions</h2>
          <p className="text-sm sm:text-base text-gray-600">Track fundraising activities and member contributions</p>
        </div>
        <div className="flex space-x-2">
          <Button variant="outline" onClick={exportActivitiesReport}>
            <Download className="mr-2 h-4 w-4" />
            Export Report
          </Button>
          <Button 
            onClick={() => setIsActivityModalOpen(true)}
            className="flex items-center space-x-2"
          >
            <Plus className="h-4 w-4" />
            <span>New Activity</span>
          </Button>
          <Button 
            onClick={() => setIsContributionModalOpen(true)}
            variant="outline"
            className="flex items-center space-x-2"
          >
            <Plus className="h-4 w-4" />
            <span>Add Contribution</span>
          </Button>
        </div>
      </div>

      {/* Activity Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Active Activities</p>
                <p className="text-3xl font-bold text-gray-900">
                  {activities.filter(a => a.status === 'active').length}
                </p>
              </div>
              <Calendar className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Activities</p>
                <p className="text-3xl font-bold text-gray-900">
                  {activities.length}
                </p>
              </div>
              <Target className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Raised</p>
                <p className="text-3xl font-bold text-gray-900">
                  ₱{activities.reduce((sum, a) => sum + parseFloat(a.currentAmount), 0).toLocaleString()}
                </p>
              </div>
              <TrendingUp className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Contributors</p>
                <p className="text-3xl font-bold text-gray-900">
                  {new Set(contributions.map(c => c.memberId)).size}
                </p>
              </div>
              <Users className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Activities List */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Fundraising Activities</CardTitle>
        </CardHeader>
        <CardContent>
          {activitiesLoading ? (
            <div>Loading activities...</div>
          ) : activities.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              No activities found. Create your first fundraising activity.
            </div>
          ) : (
            <div className="space-y-4">
              {activities.map((activity) => (
                <div key={activity.id} className="border rounded-lg p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="font-semibold text-lg">{activity.name}</h3>
                      {activity.description && (
                        <p className="text-gray-600 text-sm mt-1">{activity.description}</p>
                      )}
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge className={getStatusColor(activity.status)}>
                        {activity.status}
                      </Badge>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Delete Activity</AlertDialogTitle>
                            <AlertDialogDescription>
                              Are you sure you want to delete "{activity.name}"? This will also delete all contributions associated with this activity. This action cannot be undone.
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancel</AlertDialogCancel>
                            <AlertDialogAction
                              onClick={() => deleteActivityMutation.mutate(activity.id)}
                              className="bg-red-600 hover:bg-red-700"
                            >
                              Delete
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                      <p className="text-sm text-gray-600">Total Raised</p>
                      <p className="font-semibold">₱{parseFloat(activity.currentAmount).toLocaleString()}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600">Duration</p>
                      <p className="font-semibold">
                        {formatDate(activity.startDate)} - {activity.endDate ? formatDate(activity.endDate) : 'Ongoing'}
                      </p>
                    </div>
                  </div>

                  {/* Contributors Table for this activity */}
                  <div className="mb-4">
                    {(() => {
                      const activityContributions = contributions.filter(c => c.activityId === activity.id);
                      if (activityContributions.length === 0) {
                        return (
                          <div className="text-sm text-gray-500 text-center py-2">
                            No contributions yet
                          </div>
                        );
                      }
                      return (
                        <div>
                          <p className="text-sm font-medium text-gray-700 mb-2">Contributors ({activityContributions.length})</p>
                          <div className="border rounded-lg overflow-hidden">
                            <Table>
                              <TableHeader>
                                <TableRow>
                                  <TableHead className="py-2 text-xs">Member</TableHead>
                                  <TableHead className="py-2 text-xs">Amount</TableHead>
                                  <TableHead className="py-2 text-xs">Date</TableHead>
                                  <TableHead className="py-2 text-xs">Notes</TableHead>
                                  <TableHead className="py-2 text-xs w-12">Action</TableHead>
                                </TableRow>
                              </TableHeader>
                              <TableBody>
                                {activityContributions.map((contrib) => (
                                  <TableRow key={contrib.id}>
                                    <TableCell className="py-2 text-sm">{contrib.memberName}</TableCell>
                                    <TableCell className="py-2 text-sm">₱{parseFloat(contrib.amount).toLocaleString()}</TableCell>
                                    <TableCell className="py-2 text-sm">{formatDate(contrib.contributionDate)}</TableCell>
                                    <TableCell className="py-2 text-sm">{contrib.notes || '-'}</TableCell>
                                    <TableCell className="py-2 text-sm">
                                      <AlertDialog>
                                        <AlertDialogTrigger asChild>
                                          <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700 p-1">
                                            <Trash2 className="h-3 w-3" />
                                          </Button>
                                        </AlertDialogTrigger>
                                        <AlertDialogContent>
                                          <AlertDialogHeader>
                                            <AlertDialogTitle>Delete Contribution</AlertDialogTitle>
                                            <AlertDialogDescription>
                                              Are you sure you want to delete this ₱{parseFloat(contrib.amount).toLocaleString()} contribution from {contrib.memberName}? This action cannot be undone.
                                            </AlertDialogDescription>
                                          </AlertDialogHeader>
                                          <AlertDialogFooter>
                                            <AlertDialogCancel>Cancel</AlertDialogCancel>
                                            <AlertDialogAction
                                              onClick={() => deleteContributionMutation.mutate(contrib.id)}
                                              className="bg-red-600 hover:bg-red-700"
                                            >
                                              Delete
                                            </AlertDialogAction>
                                          </AlertDialogFooter>
                                        </AlertDialogContent>
                                      </AlertDialog>
                                    </TableCell>
                                  </TableRow>
                                ))}
                              </TableBody>
                            </Table>
                          </div>
                        </div>
                      );
                    })()}
                  </div>

                  <Button
                    onClick={() => handleAddContribution(activity)}
                    size="sm"
                    variant="outline"
                    disabled={activity.status !== 'active'}
                  >
                    Add Contribution
                  </Button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Recent Contributions */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Contributions</CardTitle>
        </CardHeader>
        <CardContent>
          {contributionsLoading ? (
            <div>Loading contributions...</div>
          ) : contributions.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              No contributions recorded yet.
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Member</TableHead>
                  <TableHead>Activity</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Notes</TableHead>
                  <TableHead className="w-12">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {contributions.slice(0, 10).map((contribution) => (
                  <TableRow key={contribution.id}>
                    <TableCell>{formatDate(contribution.contributionDate)}</TableCell>
                    <TableCell>{contribution.memberName}</TableCell>
                    <TableCell>{contribution.activityName}</TableCell>
                    <TableCell>₱{parseFloat(contribution.amount).toLocaleString()}</TableCell>
                    <TableCell>{contribution.notes || '-'}</TableCell>
                    <TableCell>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Delete Contribution</AlertDialogTitle>
                            <AlertDialogDescription>
                              Are you sure you want to delete this ₱{parseFloat(contribution.amount).toLocaleString()} contribution from {contribution.memberName} for {contribution.activityName}? This action cannot be undone.
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancel</AlertDialogCancel>
                            <AlertDialogAction
                              onClick={() => deleteContributionMutation.mutate(contribution.id)}
                              className="bg-red-600 hover:bg-red-700"
                            >
                              Delete
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Activity Modal */}
      <Dialog open={isActivityModalOpen} onOpenChange={setIsActivityModalOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Create New Activity</DialogTitle>
          </DialogHeader>
          <Form {...activityForm}>
            <form onSubmit={activityForm.handleSubmit(onSubmitActivity)} className="space-y-4">
              <FormField
                control={activityForm.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Activity Name</FormLabel>
                    <FormControl>
                      <Input placeholder="Enter activity name" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={activityForm.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea placeholder="Enter activity description" {...field} value={field.value || ""} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="grid grid-cols-2 gap-4">
                <FormField
                  control={activityForm.control}
                  name="startDate"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Start Date</FormLabel>
                      <FormControl>
                        <Input 
                          type="date" 
                          {...field}
                          value={field.value instanceof Date ? field.value.toISOString().split('T')[0] : field.value}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={activityForm.control}
                  name="endDate"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>End Date (Optional)</FormLabel>
                      <FormControl>
                        <Input 
                          type="date" 
                          {...field}
                          value={field.value instanceof Date ? field.value.toISOString().split('T')[0] : field.value || ''}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="flex justify-end space-x-2">
                <Button type="button" variant="outline" onClick={() => setIsActivityModalOpen(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={createActivityMutation.isPending}>
                  Create Activity
                </Button>
              </div>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Contribution Modal */}
      <Dialog open={isContributionModalOpen} onOpenChange={setIsContributionModalOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Record Contribution</DialogTitle>
          </DialogHeader>
          <Form {...contributionForm}>
            <form onSubmit={contributionForm.handleSubmit(onSubmitContribution)} className="space-y-4">
              <FormField
                control={contributionForm.control}
                name="activityId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Activity</FormLabel>
                    <Select onValueChange={(value) => field.onChange(Number(value))} value={field.value?.toString()}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select activity" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {activities.filter(a => a.status === 'active').map((activity) => (
                          <SelectItem key={activity.id} value={activity.id.toString()}>
                            {activity.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={contributionForm.control}
                name="memberId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Member</FormLabel>
                    <Select onValueChange={(value) => field.onChange(Number(value))} value={field.value?.toString()}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select member" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {members.map((member) => (
                          <SelectItem key={member.id} value={member.id.toString()}>
                            {member.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={contributionForm.control}
                name="amount"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Amount (₱)</FormLabel>
                    <FormControl>
                      <Input type="number" placeholder="0.00" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={contributionForm.control}
                name="contributionDate"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Contribution Date</FormLabel>
                    <FormControl>
                      <Input 
                        type="date" 
                        {...field}
                        value={field.value instanceof Date ? field.value.toISOString().split('T')[0] : field.value}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={contributionForm.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Notes (Optional)</FormLabel>
                    <FormControl>
                      <Textarea placeholder="Enter any notes" {...field} value={field.value || ""} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex justify-end space-x-2">
                <Button type="button" variant="outline" onClick={() => setIsContributionModalOpen(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={createContributionMutation.isPending}>
                  Record Contribution
                </Button>
              </div>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
    </div>
  );
}