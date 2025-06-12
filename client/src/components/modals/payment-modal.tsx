import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import type { Member } from "@shared/schema";

interface PaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  selectedMemberId?: number;
}

export default function PaymentModal({ isOpen, onClose, selectedMemberId }: PaymentModalProps) {
  const [memberId, setMemberId] = useState<string>(selectedMemberId?.toString() || "");
  const [amount, setAmount] = useState("500");
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().split('T')[0]);
  const [notes, setNotes] = useState("");
  
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: members = [] } = useQuery<Member[]>({
    queryKey: ["/api/members"],
    enabled: isOpen,
  });

  const createPaymentMutation = useMutation({
    mutationFn: async (paymentData: {
      memberId: number;
      amount: string;
      paymentDate: string;
      notes?: string;
    }) => {
      const response = await apiRequest('POST', '/api/payments', {
        ...paymentData,
        paymentDate: new Date(paymentData.paymentDate).toISOString(),
      });
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/payments"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      queryClient.invalidateQueries({ queryKey: ["/api/recent-payments"] });
      toast({
        title: "Success",
        description: "Payment recorded successfully!",
      });
      handleClose();
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: error.message || "Failed to record payment",
        variant: "destructive",
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!memberId || !amount || !paymentDate) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    createPaymentMutation.mutate({
      memberId: parseInt(memberId),
      amount,
      paymentDate,
      notes: notes.trim() || undefined,
    });
  };

  const handleClose = () => {
    setMemberId(selectedMemberId?.toString() || "");
    setAmount("500");
    setPaymentDate(new Date().toISOString().split('T')[0]);
    setNotes("");
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Record Payment</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="member">Member *</Label>
            <Select value={memberId} onValueChange={setMemberId}>
              <SelectTrigger>
                <SelectValue placeholder="Select Member" />
              </SelectTrigger>
              <SelectContent>
                {members.map((member) => (
                  <SelectItem key={member.id} value={member.id.toString()}>
                    {member.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          
          <div>
            <Label htmlFor="amount">Amount *</Label>
            <Input
              id="amount"
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="500"
              required
            />
          </div>
          
          <div>
            <Label htmlFor="paymentDate">Payment Date *</Label>
            <Input
              id="paymentDate"
              type="date"
              value={paymentDate}
              onChange={(e) => setPaymentDate(e.target.value)}
              required
            />
          </div>
          
          <div>
            <Label htmlFor="notes">Notes (Optional)</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Payment notes..."
              rows={3}
            />
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
              disabled={createPaymentMutation.isPending}
            >
              {createPaymentMutation.isPending ? "Recording..." : "Record Payment"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
