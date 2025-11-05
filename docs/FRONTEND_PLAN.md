# 🎨 Frontend Development Plan - RustCRM

## 📋 Overview

Complete React + TypeScript frontend for RustCRM with modern UI/UX.

**Stack**:
- React 18 + TypeScript
- Vite (build tool)
- TailwindCSS + shadcn/ui
- TanStack Query (data fetching)
- Zustand (state management)
- React Router (routing)

---

## 📅 Timeline: Days 21-28

### Day 21-22: Setup & Authentication

**Setup (Day 21 Morning)**:
```bash
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install

# Install dependencies
npm install react-router-dom @tanstack/react-query zustand axios
npm install -D tailwindcss postcss autoprefixer
npm install lucide-react class-variance-authority clsx tailwind-merge

# Setup Tailwind
npx tailwindcss init -p
```

**File Structure**:
```
frontend/
├── src/
│   ├── api/
│   │   ├── client.ts           # Axios instance
│   │   ├── auth.ts             # Auth API calls
│   │   └── contacts.ts         # Contact API calls
│   ├── components/
│   │   ├── ui/                 # shadcn components
│   │   ├── auth/
│   │   │   ├── LoginForm.tsx
│   │   │   └── RegisterForm.tsx
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── MainLayout.tsx
│   │   └── common/
│   │       ├── Button.tsx
│   │       └── Input.tsx
│   ├── pages/
│   │   ├── auth/
│   │   │   ├── LoginPage.tsx
│   │   │   └── RegisterPage.tsx
│   │   ├── DashboardPage.tsx
│   │   └── contacts/
│   │       ├── ContactsListPage.tsx
│   │       └── ContactDetailPage.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   └── useContacts.ts
│   ├── store/
│   │   └── authStore.ts        # Zustand store
│   ├── types/
│   │   └── index.ts            # TypeScript types
│   ├── utils/
│   │   └── cn.ts               # Class name utility
│   ├── App.tsx
│   └── main.tsx
```

**Authentication Implementation**:

`src/api/client.ts`:
```typescript
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for adding auth token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for handling errors
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired - try to refresh or logout
      localStorage.removeItem('access_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

`src/store/authStore.ts`:
```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  email: string;
  first_name?: string;
  last_name?: string;
  role: string;
}

interface AuthState {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  login: (user: User, accessToken: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      isAuthenticated: false,
      login: (user, accessToken) => {
        localStorage.setItem('access_token', accessToken);
        set({ user, accessToken, isAuthenticated: true });
      },
      logout: () => {
        localStorage.removeItem('access_token');
        set({ user: null, accessToken: null, isAuthenticated: false });
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
```

`src/pages/auth/LoginPage.tsx`:
```typescript
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiClient } from '../../api/client';
import { useAuthStore } from '../../store/authStore';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const navigate = useNavigate();
  const login = useAuthStore((state) => state.login);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await apiClient.post('/auth/login', {
        email,
        password,
      });

      const { user, access_token } = response.data;
      login(user, access_token);
      navigate('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-md space-y-8 rounded-lg bg-white p-8 shadow-lg">
        <div>
          <h2 className="text-center text-3xl font-bold">Sign in to RustCRM</h2>
        </div>
        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <div className="rounded-md bg-red-50 p-4 text-sm text-red-600">
              {error}
            </div>
          )}
          <div>
            <label htmlFor="email" className="block text-sm font-medium">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
            />
          </div>
          <div>
            <label htmlFor="password" className="block text-sm font-medium">
              Password
            </label>
            <input
              id="password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

**Deliverables**:
- Authentication flow working
- Login/Register pages
- Protected routes
- Token management

---

### Day 23-24: Dashboard & Layout

**Main Layout**:
```typescript
// src/components/layout/MainLayout.tsx
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export function MainLayout() {
  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
```

**Dashboard with Widgets**:
```typescript
// src/pages/DashboardPage.tsx
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '../api/client';

export function DashboardPage() {
  const { data: stats } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const { data } = await apiClient.get('/analytics/overview');
      return data;
    },
  });

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>

      {/* Stats Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <StatsCard
          title="Total Contacts"
          value={stats?.total_contacts}
          icon={Users}
        />
        <StatsCard
          title="Total Deals"
          value={stats?.total_deals}
          icon={DollarSign}
        />
        <StatsCard
          title="Revenue"
          value={`$${stats?.total_revenue}`}
          icon={TrendingUp}
        />
        <StatsCard
          title="Tasks"
          value={stats?.pending_tasks}
          icon={CheckSquare}
        />
      </div>

      {/* Charts */}
      <div className="grid gap-6 lg:grid-cols-2">
        <RevenueChart />
        <PipelineChart />
      </div>

      {/* Recent Activity */}
      <ActivityFeed />
    </div>
  );
}
```

**Deliverables**:
- Responsive layout with sidebar
- Dashboard with stats
- Charts (using recharts or similar)
- Activity feed

---

### Day 25: Contacts Management

**Contacts List with Table**:
```typescript
// src/pages/contacts/ContactsListPage.tsx
import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../../api/client';
import { Plus, Search, Filter } from 'lucide-react';

export function ContactsListPage() {
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['contacts', page, search],
    queryFn: async () => {
      const { data } = await apiClient.get('/contacts', {
        params: { page, per_page: 20, search },
      });
      return data;
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiClient.delete(`/contacts/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['contacts'] });
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Contacts</h1>
        <button className="flex items-center gap-2 rounded-md bg-blue-600 px-4 py-2 text-white">
          <Plus size={20} />
          Add Contact
        </button>
      </div>

      {/* Search and Filters */}
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-3 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search contacts..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-md border border-gray-300 py-2 pl-10 pr-4"
          />
        </div>
        <button className="flex items-center gap-2 rounded-md border border-gray-300 px-4 py-2">
          <Filter size={20} />
          Filters
        </button>
      </div>

      {/* Table */}
      <div className="overflow-hidden rounded-lg bg-white shadow">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                Email
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                Company
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {data?.data.map((contact: any) => (
              <tr key={contact.id}>
                <td className="whitespace-nowrap px-6 py-4">
                  {contact.first_name} {contact.last_name}
                </td>
                <td className="px-6 py-4">{contact.email}</td>
                <td className="px-6 py-4">{contact.company_name}</td>
                <td className="px-6 py-4">
                  <button onClick={() => deleteMutation.mutate(contact.id)}>
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <Pagination
        currentPage={page}
        totalPages={data?.total_pages || 0}
        onPageChange={setPage}
      />
    </div>
  );
}
```

**Deliverables**:
- Contacts list with search
- Pagination
- Create/Edit contact modal
- Delete functionality

---

### Day 26: Deals Kanban Board

**Kanban Implementation**:
```typescript
// src/pages/deals/DealsKanbanPage.tsx
import { DndContext, DragOverlay } from '@dnd-kit/core';
import { useQuery, useMutation } from '@tanstack/react-query';

const STAGES = ['Lead', 'Qualified', 'Proposal', 'Negotiation', 'Closed'];

export function DealsKanbanPage() {
  const { data: deals } = useQuery({
    queryKey: ['deals'],
    queryFn: async () => {
      const { data } = await apiClient.get('/deals');
      return data;
    },
  });

  const updateStageMutation = useMutation({
    mutationFn: ({ id, stage }: { id: string; stage: string }) =>
      apiClient.put(`/deals/${id}/stage`, { stage }),
  });

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Deals Pipeline</h1>

      <div className="flex gap-4 overflow-x-auto">
        {STAGES.map((stage) => (
          <KanbanColumn
            key={stage}
            stage={stage}
            deals={deals?.filter((d: any) => d.stage === stage) || []}
            onDrop={(dealId) =>
              updateStageMutation.mutate({ id: dealId, stage })
            }
          />
        ))}
      </div>
    </div>
  );
}
```

---

### Day 27-28: Tasks, Settings & Polish

**Tasks List**:
- Calendar view
- List view with filters
- Task creation modal
- Due date reminders

**Settings Pages**:
- User profile
- Password change
- Team management
- Integration settings

**Polish**:
- Loading states
- Error boundaries
- Toast notifications
- Responsive design testing
- Accessibility

---

## 🧪 Testing

```bash
# Install testing dependencies
npm install -D vitest @testing-library/react @testing-library/jest-dom

# Component tests
npm install -D @testing-library/user-event

# E2E tests
npm install -D playwright
```

**Component Test Example**:
```typescript
import { render, screen } from '@testing-library/react';
import { LoginPage } from './LoginPage';

describe('LoginPage', () => {
  it('renders login form', () => {
    render(<LoginPage />);
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByLabelText('Password')).toBeInTheDocument();
  });
});
```

---

## 📝 Checklist

- [ ] Project setup with Vite
- [ ] Authentication flow
- [ ] Protected routes
- [ ] Main layout with sidebar
- [ ] Dashboard with widgets
- [ ] Contacts CRUD
- [ ] Companies CRUD
- [ ] Deals Kanban
- [ ] Tasks & Calendar
- [ ] Settings pages
- [ ] Responsive design
- [ ] Loading states
- [ ] Error handling
- [ ] Tests written
- [ ] Accessibility checked

---

**Ready to build a modern, professional CRM interface! 🎨**
