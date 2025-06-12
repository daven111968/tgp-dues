import { users, members, payments, type User, type InsertUser, type Member, type InsertMember, type Payment, type InsertPayment } from "@shared/schema";

export interface IStorage {
  // User methods
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  
  // Member methods
  getMembers(): Promise<Member[]>;
  getMember(id: number): Promise<Member | undefined>;
  getMemberByBatchNumber(batchNumber: string): Promise<Member | undefined>;
  createMember(member: InsertMember): Promise<Member>;
  updateMember(id: number, member: Partial<InsertMember>): Promise<Member | undefined>;
  deleteMember(id: number): Promise<boolean>;
  
  // Payment methods
  getPayments(): Promise<Payment[]>;
  getPaymentsByMember(memberId: number): Promise<Payment[]>;
  createPayment(payment: InsertPayment): Promise<Payment>;
  getPaymentStats(): Promise<{
    totalMembers: number;
    paidMembers: number;
    pendingMembers: number;
    overdueMembers: number;
  }>;
  getRecentPayments(limit?: number): Promise<Array<Payment & { memberName: string }>>;
}

export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private members: Map<number, Member>;
  private payments: Map<number, Payment>;
  private currentUserId: number;
  private currentMemberId: number;
  private currentPaymentId: number;

  constructor() {
    this.users = new Map();
    this.members = new Map();
    this.payments = new Map();
    this.currentUserId = 1;
    this.currentMemberId = 1;
    this.currentPaymentId = 1;
    
    // Initialize with sample data
    this.initializeData();
  }

  private async initializeData() {
    // Create sample officer
    await this.createUser({
      username: "treasurer",
      password: "password123",
      name: "Chapter Treasurer",
      position: "Treasurer"
    });

    // Create sample members
    const sampleMembers = [
      {
        name: "Juan Dela Cruz",
        email: "juan.delacruz@cbc.edu.ph",
        batchNumber: "Batch-2021",
        status: "active"
      },
      {
        name: "Mark Santos",
        email: "mark.santos@cbc.edu.ph",
        batchNumber: "Batch-2021", 
        status: "active"
      },
      {
        name: "Paolo Rodriguez",
        email: "paolo.rodriguez@cbc.edu.ph",
        batchNumber: "Batch-2022",
        status: "active"
      }
    ];

    for (const member of sampleMembers) {
      await this.createMember(member);
    }

    // Create sample payments
    const now = new Date();
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 15);
    const twoMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 2, 10);

    await this.createPayment({
      memberId: 1,
      amount: "500.00",
      paymentDate: thisMonth,
      notes: "December 2024 dues"
    });

    await this.createPayment({
      memberId: 2,
      amount: "500.00", 
      paymentDate: lastMonth,
      notes: "November 2024 dues"
    });

    await this.createPayment({
      memberId: 3,
      amount: "500.00",
      paymentDate: twoMonthsAgo,
      notes: "October 2024 dues"
    });
  }

  async getUser(id: number): Promise<User | undefined> {
    return this.users.get(id);
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(
      (user) => user.username === username
    );
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const id = this.currentUserId++;
    const user: User = { ...insertUser, id };
    this.users.set(id, user);
    return user;
  }

  async getMembers(): Promise<Member[]> {
    return Array.from(this.members.values());
  }

  async getMember(id: number): Promise<Member | undefined> {
    return this.members.get(id);
  }

  async getMemberByBatchNumber(batchNumber: string): Promise<Member | undefined> {
    return Array.from(this.members.values()).find(
      (member) => member.batchNumber === batchNumber
    );
  }

  async createMember(insertMember: InsertMember): Promise<Member> {
    const id = this.currentMemberId++;
    const member: Member = { 
      ...insertMember, 
      id,
      status: insertMember.status || "active",
      joinedAt: new Date()
    };
    this.members.set(id, member);
    return member;
  }

  async updateMember(id: number, memberUpdate: Partial<InsertMember>): Promise<Member | undefined> {
    const member = this.members.get(id);
    if (!member) return undefined;
    
    const updatedMember = { ...member, ...memberUpdate };
    this.members.set(id, updatedMember);
    return updatedMember;
  }

  async deleteMember(id: number): Promise<boolean> {
    return this.members.delete(id);
  }

  async getPayments(): Promise<Payment[]> {
    return Array.from(this.payments.values());
  }

  async getPaymentsByMember(memberId: number): Promise<Payment[]> {
    return Array.from(this.payments.values()).filter(
      (payment) => payment.memberId === memberId
    );
  }

  async createPayment(insertPayment: InsertPayment): Promise<Payment> {
    const id = this.currentPaymentId++;
    const payment: Payment = { 
      ...insertPayment, 
      id,
      notes: insertPayment.notes || null,
      createdAt: new Date()
    };
    this.payments.set(id, payment);
    return payment;
  }

  async getPaymentStats(): Promise<{
    totalMembers: number;
    paidMembers: number;
    pendingMembers: number;
    overdueMembers: number;
  }> {
    const members = await this.getMembers();
    const payments = await this.getPayments();
    
    const now = new Date();
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    
    const membersWithPaymentStatus = members.map(member => {
      const memberPayments = payments.filter(p => p.memberId === member.id);
      const latestPayment = memberPayments
        .sort((a, b) => new Date(b.paymentDate).getTime() - new Date(a.paymentDate).getTime())[0];
      
      if (!latestPayment) return { ...member, status: 'overdue' };
      
      const paymentDate = new Date(latestPayment.paymentDate);
      if (paymentDate >= thisMonth) return { ...member, status: 'paid' };
      if (paymentDate >= lastMonth) return { ...member, status: 'pending' };
      return { ...member, status: 'overdue' };
    });

    return {
      totalMembers: members.length,
      paidMembers: membersWithPaymentStatus.filter(m => m.status === 'paid').length,
      pendingMembers: membersWithPaymentStatus.filter(m => m.status === 'pending').length,
      overdueMembers: membersWithPaymentStatus.filter(m => m.status === 'overdue').length,
    };
  }

  async getRecentPayments(limit = 5): Promise<Array<Payment & { memberName: string }>> {
    const payments = await this.getPayments();
    const members = await this.getMembers();
    
    const paymentsWithNames = payments.map(payment => {
      const member = members.find(m => m.id === payment.memberId);
      return {
        ...payment,
        memberName: member?.name || 'Unknown Member'
      };
    });

    return paymentsWithNames
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, limit);
  }
}

export const storage = new MemStorage();
