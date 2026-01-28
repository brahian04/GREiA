-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; 

-- 2. ENUMS
CREATE TYPE user_role AS ENUM ('admin', 'technician', 'receptionist');
CREATE TYPE ticket_status AS ENUM ('pendiente', 'revision', 'reparando', 'terminado', 'entregado', 'cancelado');
CREATE TYPE ticket_priority AS ENUM ('baja', 'media', 'alta', 'urgente');

-- 3. USERS (Vinculada a auth.users de Supabase)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role user_role DEFAULT 'technician',
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. CLIENTS
CREATE TABLE public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. INVENTORY
CREATE TABLE public.inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    quantity INTEGER DEFAULT 0 CHECK (quantity >= 0),
    min_stock INTEGER DEFAULT 5,
    cost_price DECIMAL(10, 2),
    sale_price DECIMAL(10, 2),
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. TICKETS
CREATE TABLE public.tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    human_id SERIAL, 
    client_id UUID REFERENCES public.clients(id) ON DELETE RESTRICT,
    assigned_to UUID REFERENCES public.users(id),
    device_type TEXT NOT NULL, 
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    serial_number TEXT,
    problem_description TEXT NOT NULL,
    status ticket_status DEFAULT 'pendiente',
    priority ticket_priority DEFAULT 'media',
    qr_code_data TEXT generated always as ('TICKET-' || id) stored,
    estimated_cost DECIMAL(10, 2),
    final_cost DECIMAL(10, 2),
    technical_solution TEXT, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_tickets_status ON public.tickets(status);
CREATE INDEX idx_tickets_client ON public.tickets(client_id);

-- 7. TICKET HISTORY
CREATE TABLE public.ticket_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID REFERENCES public.tickets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id),
    note TEXT NOT NULL,
    action_type TEXT, 
    media_url TEXT, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. DOCUMENTS
CREATE TABLE public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    file_path TEXT NOT NULL, 
    file_type TEXT, 
    description TEXT,
    uploaded_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. KNOWLEDGE BASE (AI MEMORY)
CREATE TABLE public.knowledge_base (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_type TEXT NOT NULL CHECK (source_type IN ('manual', 'ticket_solution')),
    source_id UUID, 
    content_chunk TEXT NOT NULL,
    metadata JSONB, 
    embedding vector(768), 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX ON public.knowledge_base USING hnsw (embedding vector_cosine_ops);

-- FUNCTIONS
CREATE OR REPLACE FUNCTION match_knowledge (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id UUID,
  content_chunk TEXT,
  source_type TEXT,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    kb.id,
    kb.content_chunk,
    kb.source_type,
    1 - (kb.embedding <=> query_embedding) as similarity
  FROM public.knowledge_base kb
  WHERE 1 - (kb.embedding <=> query_embedding) > match_threshold
  ORDER BY kb.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
