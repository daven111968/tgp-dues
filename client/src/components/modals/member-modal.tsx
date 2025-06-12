import { useState, useEffect } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import type { Member } from "@shared/schema";

interface MemberModalProps {
  isOpen: boolean;
  onClose: () => void;
  member?: Member;
}

export default function MemberModal({ isOpen, onClose, member }: MemberModalProps) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [studentId, setStudentId] = useState("");
  const [yearLevel, setYearLevel] = useState("");
  const [status, setStatus] = useState("active");
  
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isEditing = !!member;

  useEffect(() => {
    if (member) {
      setName(member.name);
      setEmail(member.email);
      setStudentId(member.studentId);
      setYearLevel(member.yearLevel);
      setStatus(member.status);
    } else {
      setName("");
      setEmail("");
      setStudentId("");
      setYearLevel("");
      setStatus("active");
    }
  }, [member]);

  const createMemberMutation = useMutation({
    mutationFn: async (memberData: {
      name: string;
      email: string;
      studentId: string;
      yearLevel: string;
      status: string;
    }) => {
      const response = await apiRequest('POST', '/api/members', memberData);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/members"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      toast({
        title: "Success",
        description: "Member created successfully!",
      });
      handleClose();
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: error.message || "Failed to create member",
        variant: "destructive",
      });
    },
  });

  const updateMemberMutation = useMutation({
    mutationFn: async (memberData: {
      name: string;
      email: string;
      studentId: string;
      yearLevel: string;
      status: string;
    }) => {
      const response = await apiRequest('PUT', `/api/members/${member!.id}`, memberData);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/members"] });
      toast({
        title: "Success",
        description: "Member updated successfully!",
      });
      handleClose();
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: error.message || "Failed to update member",
        variant: "destructive",
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name || !email || !studentId || !yearLevel) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    const memberData = {
      name: name.trim(),
      email: email.trim(),
      studentId: studentId.trim(),
      yearLevel,
      status,
    };

    if (isEditing) {
      updateMemberMutation.mutate(memberData);
    } else {
      createMemberMutation.mutate(memberData);
    }
  };

  const handleClose = () => {
    setName("");
    setEmail("");
    setStudentId("");
    setYearLevel("");
    setStatus("active");
    onClose();
  };

  const isPending = createMemberMutation.isPending || updateMemberMutation.isPending;

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Edit Member" : "Add New Member"}</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="name">Full Name *</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Enter full name"
              required
            />
          </div>
          
          <div>
            <Label htmlFor="email">Email *</Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="member@cbc.edu.ph"
              required
            />
          </div>
          
          <div>
            <Label htmlFor="studentId">Student ID *</Label>
            <Input
              id="studentId"
              value={studentId}
              onChange={(e) => setStudentId(e.target.value)}
              placeholder="2024-00001"
              required
            />
          </div>
          
          <div>
            <Label htmlFor="yearLevel">Year Level *</Label>
            <Select value={yearLevel} onValueChange={setYearLevel}>
              <SelectTrigger>
                <SelectValue placeholder="Select Year Level" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1st Year">1st Year</SelectItem>
                <SelectItem value="2nd Year">2nd Year</SelectItem>
                <SelectItem value="3rd Year">3rd Year</SelectItem>
                <SelectItem value="4th Year">4th Year</SelectItem>
                <SelectItem value="5th Year">5th Year</SelectItem>
                <SelectItem value="Graduate">Graduate</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <div>
            <Label htmlFor="status">Status</Label>
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <div className="flex space-x-3 pt-4">
            <Button 
              type="button" 
              variant="outline" 
              className="flex-1"
              onClick={handleClose}
            >
              Cancel
            </Button>
            <Button 
              type="submit" 
              className="flex-1"
              disabled={isPending}
            >
              {isPending ? "Saving..." : isEditing ? "Update Member" : "Add Member"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
