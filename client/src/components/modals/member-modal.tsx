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
  const [alexisName, setAlexisName] = useState("");
  const [address, setAddress] = useState("");
  const [batchNumbers, setBatchNumbers] = useState<string[]>([]);
  const [batchNames, setBatchNames] = useState<string[]>([]);
  const [initiationDate, setInitiationDate] = useState("");
  const [memberType, setMemberType] = useState("pure_blooded");
  const [welcomingDate, setWelcomingDate] = useState("");
  const [status, setStatus] = useState("active");
  
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isEditing = !!member;

  useEffect(() => {
    if (member) {
      setName(member.name);
      setAlexisName(member.alexisName || "");
      setAddress(member.address);
      setBatchNumbers(Array.isArray(member.batchNumber) ? member.batchNumber : member.batchNumber ? [member.batchNumber] : []);
      setBatchNames(Array.isArray(member.batchName) ? member.batchName : member.batchName ? [member.batchName] : []);
      setInitiationDate(member.initiationDate ? new Date(member.initiationDate).toISOString().split('T')[0] : "");
      setMemberType(member.memberType || "pure_blooded");
      setWelcomingDate(member.welcomingDate ? new Date(member.welcomingDate).toISOString().split('T')[0] : "");
      setStatus(member.status);
    } else {
      setName("");
      setAlexisName("");
      setAddress("");
      setBatchNumbers([]);
      setBatchNames([]);
      setInitiationDate("");
      setMemberType("pure_blooded");
      setWelcomingDate("");
      setStatus("active");
    }
  }, [member]);

  const createMemberMutation = useMutation({
    mutationFn: async (memberData: {
      name: string;
      alexisName?: string;
      address: string;
      batchNumber?: string[];
      batchName?: string[];
      initiationDate: string;
      memberType: string;
      welcomingDate?: string;
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
      alexisName?: string;
      address: string;
      batchNumber?: string[];
      batchName?: string[];
      initiationDate: string;
      memberType: string;
      welcomingDate?: string;
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
    
    // Validate required fields based on member type
    if (!name || !address || !initiationDate) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    // Batch number is required for pure blooded members only
    if (memberType === "pure_blooded" && batchNumbers.length === 0) {
      toast({
        title: "Error",
        description: "At least one batch number is required for pure blooded members",
        variant: "destructive",
      });
      return;
    }

    // Validate welcoming date for welcome members
    if (memberType === "welcome" && !welcomingDate) {
      toast({
        title: "Error",
        description: "Welcoming date is required for welcome members",
        variant: "destructive",
      });
      return;
    }

    const memberData = {
      name: name.trim(),
      alexisName: alexisName.trim() || undefined,
      address: address.trim(),
      batchNumber: memberType === "pure_blooded" && batchNumbers.length > 0 ? batchNumbers.filter(num => num.trim()) : undefined,
      batchName: batchNames.length > 0 ? batchNames.filter(name => name.trim()) : undefined,
      initiationDate: initiationDate,
      memberType: memberType,
      welcomingDate: memberType === "welcome" ? welcomingDate : undefined,
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
    setAlexisName("");
    setAddress("");
    setBatchNumbers([]);
    setBatchNames([]);
    setInitiationDate("");
    setMemberType("pure_blooded");
    setWelcomingDate("");
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
            <Label htmlFor="alexisName">Alexis Name</Label>
            <Input
              id="alexisName"
              value={alexisName}
              onChange={(e) => setAlexisName(e.target.value)}
              placeholder="Enter alexis name (optional)"
            />
          </div>
          
          <div>
            <Label htmlFor="address">Address *</Label>
            <Input
              id="address"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Enter full address"
              required
            />
          </div>
          
          {memberType === "pure_blooded" && (
            <>
              <div>
                <Label>Batch Numbers *</Label>
                <div className="space-y-2">
                  {batchNumbers.length === 0 ? (
                    <div className="flex space-x-2">
                      <Input
                        value=""
                        onChange={(e) => setBatchNumbers([e.target.value])}
                        placeholder={`Batch-${new Date().getFullYear()}`}
                      />
                    </div>
                  ) : (
                    batchNumbers.map((number, index) => (
                      <div key={index} className="flex space-x-2">
                        <Input
                          value={number}
                          onChange={(e) => {
                            const newNumbers = [...batchNumbers];
                            newNumbers[index] = e.target.value;
                            setBatchNumbers(newNumbers);
                          }}
                          placeholder={`Batch-${new Date().getFullYear()}`}
                        />
                        {batchNumbers.length > 1 && (
                          <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              const newNumbers = batchNumbers.filter((_, i) => i !== index);
                              setBatchNumbers(newNumbers);
                            }}
                          >
                            Remove
                          </Button>
                        )}
                      </div>
                    ))
                  )}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setBatchNumbers([...batchNumbers, ""])}
                  >
                    Add Batch Number
                  </Button>
                </div>
              </div>
              
              <div>
                <Label>Batch Names (Optional)</Label>
                <div className="space-y-2">
                  {batchNames.length === 0 ? (
                    <div className="text-sm text-gray-500">
                      No batch names added yet.
                    </div>
                  ) : (
                    batchNames.map((name, index) => (
                      <div key={index} className="flex space-x-2">
                        <Input
                          value={name}
                          onChange={(e) => {
                            const newNames = [...batchNames];
                            newNames[index] = e.target.value;
                            setBatchNames(newNames);
                          }}
                          placeholder="Enter batch name"
                        />
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            const newNames = batchNames.filter((_, i) => i !== index);
                            setBatchNames(newNames);
                          }}
                        >
                          Remove
                        </Button>
                      </div>
                    ))
                  )}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setBatchNames([...batchNames, ""])}
                  >
                    Add Batch Name
                  </Button>
                </div>
              </div>
            </>
          )}
          
          <div>
            <Label htmlFor="initiationDate">Date of Initiation *</Label>
            <Input
              id="initiationDate"
              type="date"
              value={initiationDate}
              onChange={(e) => setInitiationDate(e.target.value)}
              required
            />
          </div>
          
          <div>
            <Label htmlFor="memberType">Member Type *</Label>
            <Select value={memberType} onValueChange={setMemberType}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pure_blooded">Pure Blooded</SelectItem>
                <SelectItem value="welcome">Welcome</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          {memberType === "welcome" && (
            <div>
              <Label htmlFor="welcomingDate">Welcoming Date *</Label>
              <Input
                id="welcomingDate"
                type="date"
                value={welcomingDate}
                onChange={(e) => setWelcomingDate(e.target.value)}
                required
              />
            </div>
          )}
          
          <div>
            <Label htmlFor="status">Status</Label>
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
                <SelectItem value="suspended">Suspended</SelectItem>
                <SelectItem value="expelled">Expelled</SelectItem>
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