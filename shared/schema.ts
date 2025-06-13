import { pgTable, text, serial, integer, boolean, timestamp, decimal } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  name: text("name").notNull(),
  position: text("position").notNull(),
});

export const members = pgTable("members", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  alexisName: text("alexis_name"),
  address: text("address").notNull(),
  batchNumber: text("batch_number").array(),
  batchName: text("batch_name").array(),
  initiationDate: timestamp("initiation_date").notNull(),
  memberType: text("member_type").notNull().default("pure_blooded"), // pure_blooded, welcome
  welcomingDate: timestamp("welcoming_date"),
  status: text("status").notNull().default("active"), // active, inactive, suspended, expelled
  // Member login credentials
  username: text("username").unique(),
  password: text("password"),
});

export const payments = pgTable("payments", {
  id: serial("id").primaryKey(),
  memberId: integer("member_id").notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  paymentDate: timestamp("payment_date").notNull(),
  notes: text("notes"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const chapterInfo = pgTable("chapter_info", {
  id: serial("id").primaryKey(),
  chapterName: text("chapter_name").notNull(),
  chapterAddress: text("chapter_address").notNull(),
  contactEmail: text("contact_email").notNull(),
  contactPhone: text("contact_phone").notNull(),
  treasurerName: text("treasurer_name").notNull(),
  treasurerEmail: text("treasurer_email").notNull(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const activities = pgTable("activities", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  currentAmount: decimal("current_amount", { precision: 10, scale: 2 }).notNull().default("0.00"),
  status: text("status").notNull().default("active"), // active, completed, cancelled
  startDate: timestamp("start_date").notNull(),
  endDate: timestamp("end_date"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const contributions = pgTable("contributions", {
  id: serial("id").primaryKey(),
  activityId: integer("activity_id").notNull(),
  memberId: integer("member_id").notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  contributionDate: timestamp("contribution_date").notNull(),
  notes: text("notes"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const insertUserSchema = createInsertSchema(users).omit({
  id: true,
});

export const insertMemberSchema = createInsertSchema(members).omit({
  id: true,
}).extend({
  initiationDate: z.coerce.date(),
  welcomingDate: z.coerce.date().optional(),
});

export const insertPaymentSchema = createInsertSchema(payments).omit({
  id: true,
  createdAt: true,
}).extend({
  paymentDate: z.coerce.date(),
});

export const insertChapterInfoSchema = createInsertSchema(chapterInfo).omit({
  id: true,
  updatedAt: true,
});

export const insertActivitySchema = createInsertSchema(activities).omit({
  id: true,
  createdAt: true,
  currentAmount: true,
}).extend({
  startDate: z.coerce.date(),
  endDate: z.coerce.date().optional(),
});

export const insertContributionSchema = createInsertSchema(contributions).omit({
  id: true,
  createdAt: true,
}).extend({
  contributionDate: z.coerce.date(),
});

export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type Member = typeof members.$inferSelect;
export type InsertMember = z.infer<typeof insertMemberSchema>;
export type Payment = typeof payments.$inferSelect;
export type InsertPayment = z.infer<typeof insertPaymentSchema>;
export type ChapterInfo = typeof chapterInfo.$inferSelect;
export type InsertChapterInfo = z.infer<typeof insertChapterInfoSchema>;
export type Activity = typeof activities.$inferSelect;
export type InsertActivity = z.infer<typeof insertActivitySchema>;
export type Contribution = typeof contributions.$inferSelect;
export type InsertContribution = z.infer<typeof insertContributionSchema>;
