import { users, members, payments, chapterInfo, activities, contributions, type User, type InsertUser, type Member, type InsertMember, type Payment, type InsertPayment, type ChapterInfo, type InsertChapterInfo, type Activity, type InsertActivity, type Contribution, type InsertContribution } from "@shared/schema";
import { db } from "./db";
import { eq, sql } from "drizzle-orm";

export interface IStorage {
  // User methods
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUser(id: number, user: Partial<InsertUser>): Promise<User | undefined>;
  
  // Member methods
  getMembers(): Promise<Member[]>;
  getMember(id: number): Promise<Member | undefined>;
  getMemberByBatchNumber(batchNumber: string): Promise<Member | undefined>;
  getMemberByUsername(username: string): Promise<Member | undefined>;
  createMember(member: InsertMember): Promise<Member>;
  updateMember(id: number, member: Partial<InsertMember>): Promise<Member | undefined>;
  deleteMember(id: number): Promise<boolean>;
  
  // Payment methods
  getPayments(): Promise<Payment[]>;
  getPaymentsByMember(memberId: number): Promise<Payment[]>;
  createPayment(payment: InsertPayment): Promise<Payment>;
  clearAllPayments(): Promise<boolean>;
  getPaymentStats(): Promise<{
    totalMembers: number;
    paidMembers: number;
    pendingMembers: number;
    overdueMembers: number;
  }>;
  getRecentPayments(limit?: number): Promise<Array<Payment & { memberName: string }>>;
  
  // Chapter info methods
  getChapterInfo(): Promise<ChapterInfo | undefined>;
  updateChapterInfo(info: InsertChapterInfo): Promise<ChapterInfo>;
  
  // Activity methods
  getActivities(): Promise<Activity[]>;
  getActivity(id: number): Promise<Activity | undefined>;
  createActivity(activity: InsertActivity): Promise<Activity>;
  updateActivity(id: number, activity: Partial<InsertActivity>): Promise<Activity | undefined>;
  deleteActivity(id: number): Promise<boolean>;
  
  // Contribution methods
  getContributions(): Promise<Array<Contribution & { memberName: string; activityName: string }>>;
  getContributionsByActivity(activityId: number): Promise<Array<Contribution & { memberName: string }>>;
  createContribution(contribution: InsertContribution): Promise<Contribution>;
  deleteContribution(id: number): Promise<boolean>;
}

export class DatabaseStorage implements IStorage {
  constructor() {
    // Initialize with sample data if needed
    this.initializeData();
  }

  private async initializeData() {
    try {
      // Check if users table already has data
      const existingUsers = await db.select().from(users).limit(1);
      if (existingUsers.length > 0) {
        return; // Data already exists
      }

      // Create sample officer
      await this.createUser({
        username: "treasurer",
        password: "password123",
        name: "Chapter Master Keeper of the Chest",
        position: "Master Keeper of the Chest"
      });

      // Create sample members
      const sampleMembers: InsertMember[] = [
        {
          name: "Juan Dela Cruz",
          address: "123 Main St, Quezon City",
          batchNumber: ["Batch-2021"],
          initiationDate: new Date('2021-03-15'),
          memberType: "pure_blooded",
          status: "active",
          username: "juan.delacruz",
          password: "member123"
        },
        {
          name: "Mark Santos",
          address: "456 Rizal Ave, Manila",
          batchNumber: ["Batch-2021"], 
          initiationDate: new Date('2021-04-20'),
          memberType: "pure_blooded",
          status: "active",
          username: "mark.santos",
          password: "member123"
        },
        {
          name: "Paolo Rodriguez",
          address: "789 EDSA, Makati City",
          initiationDate: new Date('2022-02-10'),
          memberType: "welcome",
          welcomingDate: new Date('2022-03-01'),
          status: "active",
          username: "paolo.rodriguez",
          password: "member123"
        }
      ];

      const createdMembers = [];
      for (const member of sampleMembers) {
        const created = await this.createMember(member);
        createdMembers.push(created);
      }

      // Create sample payments
      const now = new Date();
      const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 15);
      const twoMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 2, 10);

      if (createdMembers.length >= 3) {
        await this.createPayment({
          memberId: createdMembers[0].id,
          amount: "500.00",
          paymentDate: thisMonth,
          notes: `${thisMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })} dues`
        });

        await this.createPayment({
          memberId: createdMembers[1].id,
          amount: "500.00", 
          paymentDate: lastMonth,
          notes: `${lastMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })} dues`
        });

        await this.createPayment({
          memberId: createdMembers[2].id,
          amount: "500.00",
          paymentDate: twoMonthsAgo,
          notes: `${twoMonthsAgo.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })} dues`
        });
      }
    } catch (error) {
      console.log('Sample data initialization skipped:', error);
    }
  }

  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user || undefined;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user || undefined;
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const [user] = await db
      .insert(users)
      .values(insertUser)
      .returning();
    return user;
  }

  async updateUser(id: number, userUpdate: Partial<InsertUser>): Promise<User | undefined> {
    const [user] = await db
      .update(users)
      .set(userUpdate)
      .where(eq(users.id, id))
      .returning();
    return user || undefined;
  }

  async getMembers(): Promise<Member[]> {
    return await db.select().from(members);
  }

  async getMember(id: number): Promise<Member | undefined> {
    const [member] = await db.select().from(members).where(eq(members.id, id));
    return member || undefined;
  }

  async getMemberByBatchNumber(batchNumber: string): Promise<Member | undefined> {
    // This function is deprecated since batch numbers are now arrays
    // Kept for backward compatibility but not used for validation
    return undefined;
  }

  async getMemberByUsername(username: string): Promise<Member | undefined> {
    const [member] = await db.select().from(members).where(eq(members.username, username));
    return member || undefined;
  }

  async createMember(insertMember: InsertMember): Promise<Member> {
    const [member] = await db
      .insert(members)
      .values(insertMember)
      .returning();
    return member;
  }

  async updateMember(id: number, memberUpdate: Partial<InsertMember>): Promise<Member | undefined> {
    const [member] = await db
      .update(members)
      .set(memberUpdate)
      .where(eq(members.id, id))
      .returning();
    return member || undefined;
  }

  async deleteMember(id: number): Promise<boolean> {
    const result = await db.delete(members).where(eq(members.id, id));
    return (result.rowCount || 0) > 0;
  }

  async getPayments(): Promise<Payment[]> {
    return await db.select().from(payments);
  }

  async getPaymentsByMember(memberId: number): Promise<Payment[]> {
    return await db.select().from(payments).where(eq(payments.memberId, memberId));
  }

  async createPayment(insertPayment: InsertPayment): Promise<Payment> {
    const [payment] = await db
      .insert(payments)
      .values(insertPayment)
      .returning();
    return payment;
  }

  async clearAllPayments(): Promise<boolean> {
    try {
      await db.delete(payments);
      return true;
    } catch (error) {
      console.error('Error clearing payments:', error);
      return false;
    }
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

  // Chapter info methods
  async getChapterInfo(): Promise<ChapterInfo | undefined> {
    const [info] = await db.select().from(chapterInfo).limit(1);
    return info || undefined;
  }

  async updateChapterInfo(info: InsertChapterInfo): Promise<ChapterInfo> {
    const existing = await this.getChapterInfo();
    
    if (existing) {
      const [updated] = await db
        .update(chapterInfo)
        .set({ ...info, updatedAt: new Date() })
        .where(eq(chapterInfo.id, existing.id))
        .returning();
      return updated;
    } else {
      const [created] = await db
        .insert(chapterInfo)
        .values(info)
        .returning();
      return created;
    }
  }

  // Activity methods
  async getActivities(): Promise<Activity[]> {
    return await db.select().from(activities).orderBy(sql`${activities.createdAt} DESC`);
  }

  async getActivity(id: number): Promise<Activity | undefined> {
    const [activity] = await db.select().from(activities).where(eq(activities.id, id));
    return activity || undefined;
  }

  async createActivity(insertActivity: InsertActivity): Promise<Activity> {
    const [activity] = await db
      .insert(activities)
      .values(insertActivity)
      .returning();
    return activity;
  }

  async updateActivity(id: number, activityUpdate: Partial<InsertActivity>): Promise<Activity | undefined> {
    const [activity] = await db
      .update(activities)
      .set(activityUpdate)
      .where(eq(activities.id, id))
      .returning();
    return activity || undefined;
  }

  async deleteActivity(id: number): Promise<boolean> {
    try {
      // First delete all contributions related to this activity
      await db.delete(contributions).where(eq(contributions.activityId, id));
      
      // Then delete the activity
      const result = await db.delete(activities).where(eq(activities.id, id));
      return (result.rowCount || 0) > 0;
    } catch (error) {
      console.error('Error deleting activity:', error);
      return false;
    }
  }

  // Contribution methods
  async getContributions(): Promise<Array<Contribution & { memberName: string; activityName: string }>> {
    const result = await db
      .select({
        id: contributions.id,
        activityId: contributions.activityId,
        memberId: contributions.memberId,
        amount: contributions.amount,
        contributionDate: contributions.contributionDate,
        notes: contributions.notes,
        createdAt: contributions.createdAt,
        memberName: members.name,
        activityName: activities.name,
      })
      .from(contributions)
      .innerJoin(members, eq(contributions.memberId, members.id))
      .innerJoin(activities, eq(contributions.activityId, activities.id))
      .orderBy(sql`${contributions.createdAt} DESC`);

    return result;
  }

  async getContributionsByActivity(activityId: number): Promise<Array<Contribution & { memberName: string }>> {
    const result = await db
      .select({
        id: contributions.id,
        activityId: contributions.activityId,
        memberId: contributions.memberId,
        amount: contributions.amount,
        contributionDate: contributions.contributionDate,
        notes: contributions.notes,
        createdAt: contributions.createdAt,
        memberName: members.name,
      })
      .from(contributions)
      .innerJoin(members, eq(contributions.memberId, members.id))
      .where(eq(contributions.activityId, activityId))
      .orderBy(sql`${contributions.createdAt} DESC`);

    return result;
  }

  async createContribution(insertContribution: InsertContribution): Promise<Contribution> {
    const [contribution] = await db
      .insert(contributions)
      .values(insertContribution)
      .returning();

    // Update activity current amount
    await db
      .update(activities)
      .set({
        currentAmount: sql`${activities.currentAmount} + ${insertContribution.amount}`
      })
      .where(eq(activities.id, insertContribution.activityId));

    return contribution;
  }

  async deleteContribution(id: number): Promise<boolean> {
    try {
      // Get the contribution to subtract its amount from activity
      const [contribution] = await db.select().from(contributions).where(eq(contributions.id, id));
      
      if (!contribution) {
        return false;
      }

      // Delete the contribution
      const result = await db.delete(contributions).where(eq(contributions.id, id));
      
      if ((result.rowCount || 0) > 0) {
        // Update activity current amount by subtracting the contribution
        await db
          .update(activities)
          .set({
            currentAmount: sql`${activities.currentAmount} - ${contribution.amount}`
          })
          .where(eq(activities.id, contribution.activityId));
        
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Error deleting contribution:', error);
      return false;
    }
  }
}

export const storage = new DatabaseStorage();
