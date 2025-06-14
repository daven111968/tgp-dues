import { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { useMutation } from "@tanstack/react-query";
import { apiRequest } from "./queryClient";

interface User {
  id: number;
  username: string;
  name: string;
  position?: string;
  accountType: 'admin' | 'member';
}

interface AuthContextType {
  user: User | null;
  login: (username: string, password: string, accountType?: 'admin' | 'member') => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const loginMutation = useMutation({
    mutationFn: async ({ username, password, accountType }: { username: string; password: string; accountType: 'admin' | 'member' }) => {
      const response = await apiRequest('POST', '/api/auth/login', { username, password, accountType });
      return response.json();
    },
    onSuccess: (data) => {
      setUser(data.user);
      localStorage.setItem('user', JSON.stringify(data.user));
    },
  });

  const login = async (username: string, password: string, accountType: 'admin' | 'member' = 'admin') => {
    await loginMutation.mutateAsync({ username, password, accountType });
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('user');
  };

  useEffect(() => {
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      setUser(JSON.parse(savedUser));
    }
  }, []);

  return (
    <AuthContext.Provider value={{
      user,
      login,
      logout,
      isLoading: loginMutation.isPending
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
