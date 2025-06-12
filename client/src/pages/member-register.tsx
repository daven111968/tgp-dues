import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { UserPlus, AlertCircle, CheckCircle } from "lucide-react";
import { Link } from "wouter";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function MemberRegister() {
  const [formData, setFormData] = useState({
    name: "",
    alexisName: "",
    address: "",
    batchNumber: "",
    batchName: "",
    initiationDate: "",
    memberType: "pure_blooded",
    welcomingDate: "",
    username: "",
    password: "",
    confirmPassword: ""
  });
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const { toast } = useToast();

  const registerMutation = useMutation({
    mutationFn: async (data: any) => {
      const response = await apiRequest('POST', '/api/members/register', data);
      return response.json();
    },
    onSuccess: () => {
      setSuccess(true);
      setError("");
      toast({
        title: "Registration Successful",
        description: "Your account has been created. You can now sign in.",
      });
    },
    onError: (err: any) => {
      setError(err.message || "Registration failed");
      toast({
        title: "Registration Failed",
        description: err.message || "Please try again",
        variant: "destructive",
      });
    }
  });

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    // Validation
    if (!formData.name || !formData.address || !formData.initiationDate || !formData.username || !formData.password) {
      setError("Please fill in all required fields");
      return;
    }

    if (formData.memberType === "pure_blooded" && !formData.batchNumber) {
      setError("Batch number is required for pure blooded members");
      return;
    }

    if (formData.memberType === "welcome" && !formData.welcomingDate) {
      setError("Welcoming date is required for welcome members");
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    if (formData.password.length < 6) {
      setError("Password must be at least 6 characters long");
      return;
    }

    // Prepare data for submission
    const submitData = {
      name: formData.name.trim(),
      alexisName: formData.alexisName.trim() || undefined,
      address: formData.address.trim(),
      batchNumber: formData.memberType === "pure_blooded" ? formData.batchNumber.trim() : undefined,
      batchName: formData.batchName.trim() || undefined,
      initiationDate: formData.initiationDate,
      memberType: formData.memberType,
      welcomingDate: formData.memberType === "welcome" ? formData.welcomingDate : undefined,
      username: formData.username.trim(),
      password: formData.password,
      status: "active"
    };

    registerMutation.mutate(submitData);
  };

  if (success) {
    return (
      <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div className="sm:mx-auto sm:w-full sm:max-w-md">
          <Card className="shadow-lg">
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <CheckCircle className="h-8 w-8 text-green-600" />
                </div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">Registration Successful!</h2>
                <p className="text-gray-600 mb-6">
                  Your account has been created successfully. You can now sign in to access your member portal.
                </p>
                <div className="space-y-3">
                  <Link href="/member-login">
                    <Button className="w-full">
                      Sign In Now
                    </Button>
                  </Link>
                  <Link href="/login">
                    <Button variant="outline" className="w-full">
                      Admin Login
                    </Button>
                  </Link>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-2xl">
        <div className="flex justify-center">
          <div className="w-16 h-16 bg-primary rounded-xl flex items-center justify-center">
            <UserPlus className="text-white text-2xl" />
          </div>
        </div>
        <h2 className="mt-6 text-center text-3xl font-bold text-gray-900">
          Member Registration
        </h2>
        <p className="mt-2 text-center text-sm text-gray-600">
          Join the Tau Gamma Phi Rahugan CBC Chapter
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-2xl">
        <Card className="shadow-lg">
          <CardHeader>
            <CardTitle className="text-center">Create Your Account</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded flex items-center gap-2">
                  <AlertCircle className="h-4 w-4" />
                  <span className="text-sm">{error}</span>
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <Label htmlFor="name">Full Name *</Label>
                  <Input
                    id="name"
                    type="text"
                    value={formData.name}
                    onChange={(e) => handleInputChange("name", e.target.value)}
                    placeholder="Enter your full name"
                    required
                    className="mt-1"
                  />
                </div>

                <div>
                  <Label htmlFor="alexisName">Alexis Name</Label>
                  <Input
                    id="alexisName"
                    type="text"
                    value={formData.alexisName}
                    onChange={(e) => handleInputChange("alexisName", e.target.value)}
                    placeholder="Enter alexis name (optional)"
                    className="mt-1"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="address">Address *</Label>
                <Input
                  id="address"
                  type="text"
                  value={formData.address}
                  onChange={(e) => handleInputChange("address", e.target.value)}
                  placeholder="Enter your full address"
                  required
                  className="mt-1"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <Label htmlFor="memberType">Member Type *</Label>
                  <Select value={formData.memberType} onValueChange={(value) => handleInputChange("memberType", value)}>
                    <SelectTrigger className="mt-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pure_blooded">Pure Blooded</SelectItem>
                      <SelectItem value="welcome">Welcome</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="initiationDate">Date of Initiation *</Label>
                  <Input
                    id="initiationDate"
                    type="date"
                    value={formData.initiationDate}
                    onChange={(e) => handleInputChange("initiationDate", e.target.value)}
                    required
                    className="mt-1"
                  />
                </div>
              </div>

              {formData.memberType === "pure_blooded" && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <Label htmlFor="batchNumber">Batch Number *</Label>
                    <Input
                      id="batchNumber"
                      type="text"
                      value={formData.batchNumber}
                      onChange={(e) => handleInputChange("batchNumber", e.target.value)}
                      placeholder={`e.g., Batch-${new Date().getFullYear()}`}
                      required
                      className="mt-1"
                    />
                  </div>

                  <div>
                    <Label htmlFor="batchName">Batch Name</Label>
                    <Input
                      id="batchName"
                      type="text"
                      value={formData.batchName}
                      onChange={(e) => handleInputChange("batchName", e.target.value)}
                      placeholder="Enter batch name (optional)"
                      className="mt-1"
                    />
                  </div>
                </div>
              )}

              {formData.memberType === "welcome" && (
                <div>
                  <Label htmlFor="welcomingDate">Welcoming Date *</Label>
                  <Input
                    id="welcomingDate"
                    type="date"
                    value={formData.welcomingDate}
                    onChange={(e) => handleInputChange("welcomingDate", e.target.value)}
                    required
                    className="mt-1"
                  />
                </div>
              )}

              <div className="border-t pt-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Account Credentials</h3>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <Label htmlFor="username">Username *</Label>
                    <Input
                      id="username"
                      type="text"
                      value={formData.username}
                      onChange={(e) => handleInputChange("username", e.target.value)}
                      placeholder="Choose a username"
                      required
                      className="mt-1"
                    />
                  </div>

                  <div>
                    <Label htmlFor="password">Password *</Label>
                    <Input
                      id="password"
                      type="password"
                      value={formData.password}
                      onChange={(e) => handleInputChange("password", e.target.value)}
                      placeholder="Enter password (min 6 characters)"
                      required
                      className="mt-1"
                    />
                  </div>
                </div>

                <div className="mt-4">
                  <Label htmlFor="confirmPassword">Confirm Password *</Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    value={formData.confirmPassword}
                    onChange={(e) => handleInputChange("confirmPassword", e.target.value)}
                    placeholder="Confirm your password"
                    required
                    className="mt-1"
                  />
                </div>
              </div>

              <Button
                type="submit"
                className="w-full"
                disabled={registerMutation.isPending}
              >
                {registerMutation.isPending ? "Creating Account..." : "Create Account"}
              </Button>
            </form>

            <div className="mt-6 text-center">
              <p className="text-sm text-gray-600">
                Already have an account?{" "}
                <Link href="/member-login">
                  <a className="font-medium text-primary hover:text-blue-500">
                    Sign In
                  </a>
                </Link>
              </p>
              <p className="text-sm text-gray-600 mt-2">
                Are you an administrator?{" "}
                <Link href="/login">
                  <a className="font-medium text-primary hover:text-blue-500">
                    Admin Login
                  </a>
                </Link>
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}