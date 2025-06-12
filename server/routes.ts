import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertMemberSchema, insertPaymentSchema, insertChapterInfoSchema, insertActivitySchema, insertContributionSchema, insertUserSchema } from "@shared/schema";
import { z } from "zod";

const loginSchema = z.object({
  username: z.string(),
  password: z.string(),
});

export async function registerRoutes(app: Express): Promise<Server> {
  // Auth routes
  app.post("/api/login", async (req, res) => {
    try {
      const { username, password } = loginSchema.parse(req.body);
      const user = await storage.getUserByUsername(username);
      
      if (!user || user.password !== password) {
        return res.status(401).json({ message: "Invalid credentials" });
      }
      
      res.json({ user: { id: user.id, username: user.username, name: user.name, position: user.position } });
    } catch (error) {
      res.status(400).json({ message: "Invalid request" });
    }
  });

  // User account update endpoint
  app.patch("/api/users/current", async (req, res) => {
    try {
      // For simplicity, we'll assume the user ID is 1 (the default admin user)
      // In a real app, you'd get this from session/JWT
      const userId = 1;
      
      const userUpdateSchema = insertUserSchema.partial().omit({ password: true });
      const userData = userUpdateSchema.parse(req.body);
      
      const updatedUser = await storage.updateUser(userId, userData);
      
      if (!updatedUser) {
        return res.status(404).json({ message: "User not found" });
      }
      
      res.json({ 
        user: { 
          id: updatedUser.id, 
          username: updatedUser.username, 
          name: updatedUser.name, 
          position: updatedUser.position 
        } 
      });
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid user data", errors: error.errors });
      }
      res.status(500).json({ message: "Failed to update user account" });
    }
  });

  // Member routes
  app.get("/api/members", async (req, res) => {
    try {
      const members = await storage.getMembers();
      res.json(members);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch members" });
    }
  });

  app.get("/api/members/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const member = await storage.getMember(id);
      
      if (!member) {
        return res.status(404).json({ message: "Member not found" });
      }
      
      res.json(member);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch member" });
    }
  });

  app.post("/api/members", async (req, res) => {
    try {
      // Convert date strings to Date objects
      const requestBody = {
        ...req.body,
        initiationDate: req.body.initiationDate ? new Date(req.body.initiationDate) : undefined,
        welcomingDate: req.body.welcomingDate ? new Date(req.body.welcomingDate) : undefined
      };
      
      const memberData = insertMemberSchema.parse(requestBody);
      
      // Check if batch number already exists
      const existingMember = await storage.getMemberByBatchNumber(memberData.batchNumber);
      if (existingMember) {
        return res.status(400).json({ message: "Batch number already exists" });
      }
      
      const member = await storage.createMember(memberData);
      res.status(201).json(member);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid member data", errors: error.errors });
      }
      res.status(500).json({ message: "Failed to create member" });
    }
  });

  app.put("/api/members/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      
      // Convert date strings to Date objects if provided
      const requestBody = {
        ...req.body,
        initiationDate: req.body.initiationDate ? new Date(req.body.initiationDate) : undefined,
        welcomingDate: req.body.welcomingDate ? new Date(req.body.welcomingDate) : undefined
      };
      
      const memberData = insertMemberSchema.partial().parse(requestBody);
      
      const updatedMember = await storage.updateMember(id, memberData);
      
      if (!updatedMember) {
        return res.status(404).json({ message: "Member not found" });
      }
      
      res.json(updatedMember);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid member data", errors: error.errors });
      }
      res.status(500).json({ message: "Failed to update member" });
    }
  });

  app.delete("/api/members/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const deleted = await storage.deleteMember(id);
      
      if (!deleted) {
        return res.status(404).json({ message: "Member not found" });
      }
      
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ message: "Failed to delete member" });
    }
  });

  // Payment routes
  app.get("/api/payments", async (req, res) => {
    try {
      const payments = await storage.getPayments();
      res.json(payments);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch payments" });
    }
  });

  app.get("/api/payments/member/:memberId", async (req, res) => {
    try {
      const memberId = parseInt(req.params.memberId);
      const payments = await storage.getPaymentsByMember(memberId);
      res.json(payments);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch member payments" });
    }
  });

  app.post("/api/payments", async (req, res) => {
    try {
      const paymentData = insertPaymentSchema.parse(req.body);
      const payment = await storage.createPayment(paymentData);
      res.status(201).json(payment);
    } catch (error) {
      if (error instanceof z.ZodError) {
        console.log("Payment validation errors:", error.errors);
        return res.status(400).json({ message: "Invalid payment data", errors: error.errors });
      }
      console.error("Payment creation error:", error);
      res.status(500).json({ message: "Failed to create payment" });
    }
  });

  app.delete("/api/payments/clear", async (req, res) => {
    try {
      const success = await storage.clearAllPayments();
      if (success) {
        res.json({ message: "All payments cleared successfully" });
      } else {
        res.status(500).json({ error: "Failed to clear payments" });
      }
    } catch (error) {
      console.error('Error clearing payments:', error);
      res.status(500).json({ error: "Failed to clear payments" });
    }
  });

  // Dashboard stats
  app.get("/api/stats", async (req, res) => {
    try {
      const stats = await storage.getPaymentStats();
      res.json(stats);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch stats" });
    }
  });

  app.get("/api/recent-payments", async (req, res) => {
    try {
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 5;
      const recentPayments = await storage.getRecentPayments(limit);
      res.json(recentPayments);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch recent payments" });
    }
  });

  // Chapter info routes
  app.get("/api/chapter-info", async (req, res) => {
    try {
      const chapterInfo = await storage.getChapterInfo();
      res.json(chapterInfo);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch chapter info" });
    }
  });

  app.post("/api/chapter-info", async (req, res) => {
    try {
      const chapterData = insertChapterInfoSchema.parse(req.body);
      const chapterInfo = await storage.updateChapterInfo(chapterData);
      res.json(chapterInfo);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid chapter info data", errors: error.errors });
      }
      res.status(500).json({ message: "Failed to update chapter info" });
    }
  });

  // Activities routes
  app.get("/api/activities", async (req, res) => {
    try {
      const activities = await storage.getActivities();
      res.json(activities);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch activities" });
    }
  });

  app.post("/api/activities", async (req, res) => {
    try {
      const activityData = insertActivitySchema.parse(req.body);
      const activity = await storage.createActivity(activityData);
      res.status(201).json(activity);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid activity data", errors: error.errors });
      }
      res.status(500).json({ message: "Failed to create activity" });
    }
  });

  app.delete("/api/activities/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const deleted = await storage.deleteActivity(id);
      
      if (!deleted) {
        return res.status(404).json({ message: "Activity not found" });
      }
      
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ message: "Failed to delete activity" });
    }
  });

  // Contributions routes
  app.get("/api/contributions", async (req, res) => {
    try {
      const contributions = await storage.getContributions();
      res.json(contributions);
    } catch (error) {
      res.status(500).json({ message: "Failed to fetch contributions" });
    }
  });

  app.post("/api/contributions", async (req, res) => {
    try {
      const contributionData = insertContributionSchema.parse(req.body);
      const contribution = await storage.createContribution(contributionData);
      res.status(201).json(contribution);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid contribution data", errors: error.errors });
      }
      res.status(500).json({ message: "Failed to create contribution" });
    }
  });

  app.delete("/api/contributions/:id", async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const deleted = await storage.deleteContribution(id);
      
      if (!deleted) {
        return res.status(404).json({ message: "Contribution not found" });
      }
      
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ message: "Failed to delete contribution" });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}
