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
  const [aliasName, setAliasName] = useState("");
  const [email, setEmail] = useState("");
  const [batchNumber, setBatchNumber] = useState("");
  const [batchName, setBatchName] = useState("");
  const [status, setStatus] = useState("active");
  
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isEditing = !!member;

  useEffect(() => {
    if (member) {
      setName(member.name);
      setAliasName(member.aliasName || "");
      setEmail(member.email);
      setBatchNumber(member.batchNumber);
      setBatchName(member.batchName || "");
      setStatus(member.status);
    } else {
      setName("");
      setAliasName("");
      setEmail("");
      setBatchNumber("");
      setBatchName("");
      setStatus("active");
    }
  }, [member]);

  const createMemberMutation = useMutation({
    mutationFn: async (memberData: {
      name: string;
      aliasName?: string;
      email: string;
      batchNumber: string;
      batchName?: string;
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
      aliasName?: string;
      email: string;
      batchNumber: string;
      batchName?: string;
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
    
    if (!name || !email || !batchNumber) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    const memberData = {
      name: name.trim(),
      aliasName: aliasName.trim() || undefined,
      email: email.trim(),
      batchNumber: batchNumber.trim(),
      batchName: batchName.trim() || undefined,
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
    setBatchNumber("");
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
            <Label htmlFor="batchNumber">Batch Number *</Label>
            <Input
              id="batchNumber"
              value={batchNumber}
              onChange={(e) => setBatchNumber(e.target.value)}
              placeholder="Batch-2024"
              required
            />
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