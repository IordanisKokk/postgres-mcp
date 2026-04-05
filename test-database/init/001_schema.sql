CREATE TABLE countries (
  id BIGSERIAL PRIMARY KEY,
  code CHAR(2) NOT NULL UNIQUE,
  name TEXT NOT NULL,
  timezone TEXT NOT NULL
);

CREATE TABLE customers (
  id BIGSERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  birth_date DATE,
  marketing_opt_in BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'suspended')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE customer_addresses (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  line_1 TEXT NOT NULL,
  line_2 TEXT,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  country_id BIGINT NOT NULL REFERENCES countries(id),
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  parent_id BIGINT REFERENCES categories(id),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE brands (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  headquarters_country_id BIGINT REFERENCES countries(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  sku TEXT NOT NULL UNIQUE,
  category_id BIGINT NOT NULL REFERENCES categories(id),
  brand_id BIGINT NOT NULL REFERENCES brands(id),
  name TEXT NOT NULL,
  description TEXT,
  base_price NUMERIC(10, 2) NOT NULL CHECK (base_price >= 0),
  weight_grams INTEGER NOT NULL CHECK (weight_grams > 0),
  status TEXT NOT NULL CHECK (status IN ('active', 'discontinued', 'draft')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_prices (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  effective_from TIMESTAMPTZ NOT NULL,
  effective_to TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (effective_to IS NULL OR effective_to > effective_from)
);

CREATE TABLE warehouses (
  id BIGSERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  country_id BIGINT NOT NULL REFERENCES countries(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE inventory (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id BIGINT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  on_hand_qty INTEGER NOT NULL CHECK (on_hand_qty >= 0),
  reserved_qty INTEGER NOT NULL CHECK (reserved_qty >= 0),
  reorder_point INTEGER NOT NULL CHECK (reorder_point >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, warehouse_id)
);

CREATE TABLE suppliers (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  contact_name TEXT,
  contact_email TEXT,
  country_id BIGINT REFERENCES countries(id),
  lead_time_days INTEGER NOT NULL CHECK (lead_time_days > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE purchase_orders (
  id BIGSERIAL PRIMARY KEY,
  po_number TEXT NOT NULL UNIQUE,
  supplier_id BIGINT NOT NULL REFERENCES suppliers(id),
  warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),
  status TEXT NOT NULL CHECK (status IN ('draft', 'submitted', 'shipped', 'received', 'cancelled')),
  ordered_at TIMESTAMPTZ NOT NULL,
  expected_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (received_at IS NULL OR received_at >= ordered_at)
);

CREATE TABLE purchase_order_items (
  id BIGSERIAL PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id),
  quantity_ordered INTEGER NOT NULL CHECK (quantity_ordered > 0),
  quantity_received INTEGER NOT NULL CHECK (quantity_received >= 0),
  unit_cost NUMERIC(10, 2) NOT NULL CHECK (unit_cost >= 0),
  UNIQUE (purchase_order_id, product_id)
);

CREATE TABLE orders (
  id BIGSERIAL PRIMARY KEY,
  order_number TEXT NOT NULL UNIQUE,
  customer_id BIGINT NOT NULL REFERENCES customers(id),
  shipping_address_id BIGINT REFERENCES customer_addresses(id),
  billing_address_id BIGINT REFERENCES customer_addresses(id),
  status TEXT NOT NULL CHECK (status IN ('pending_payment', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded')),
  source_channel TEXT NOT NULL CHECK (source_channel IN ('web', 'ios', 'android', 'support')),
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0,
  discount_total NUMERIC(12, 2) NOT NULL DEFAULT 0,
  tax_total NUMERIC(12, 2) NOT NULL DEFAULT 0,
  shipping_total NUMERIC(12, 2) NOT NULL DEFAULT 0,
  total NUMERIC(12, 2) NOT NULL DEFAULT 0,
  placed_at TIMESTAMPTZ NOT NULL,
  paid_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (subtotal >= 0 AND discount_total >= 0 AND tax_total >= 0 AND shipping_total >= 0 AND total >= 0)
);

CREATE TABLE order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
  discount_pct NUMERIC(5, 4) NOT NULL DEFAULT 0 CHECK (discount_pct >= 0 AND discount_pct <= 1),
  line_total NUMERIC(12, 2) NOT NULL CHECK (line_total >= 0),
  UNIQUE (order_id, id)
);

CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'authorized', 'captured', 'failed', 'refunded')),
  amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
  transaction_ref TEXT NOT NULL UNIQUE,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE shipments (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),
  carrier TEXT NOT NULL,
  service_level TEXT NOT NULL,
  tracking_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL CHECK (status IN ('label_created', 'in_transit', 'delivered', 'exception', 'returned')),
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (delivered_at IS NULL OR shipped_at IS NULL OR delivered_at >= shipped_at)
);

CREATE TABLE shipment_events (
  id BIGSERIAL PRIMARY KEY,
  shipment_id BIGINT NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  location TEXT,
  event_time TIMESTAMPTZ NOT NULL,
  details TEXT
);

CREATE TABLE reviews (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(id),
  product_id BIGINT NOT NULL REFERENCES products(id),
  order_item_id BIGINT REFERENCES order_items(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title TEXT,
  body TEXT,
  verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (customer_id, product_id, order_item_id)
);

CREATE TABLE support_tickets (
  id BIGSERIAL PRIMARY KEY,
  ticket_number TEXT NOT NULL UNIQUE,
  customer_id BIGINT NOT NULL REFERENCES customers(id),
  order_id BIGINT REFERENCES orders(id),
  subject TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('open', 'pending_customer', 'resolved', 'closed')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  CHECK (resolved_at IS NULL OR resolved_at >= created_at)
);

CREATE TABLE support_ticket_messages (
  id BIGSERIAL PRIMARY KEY,
  ticket_id BIGINT NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  author_role TEXT NOT NULL CHECK (author_role IN ('customer', 'agent', 'system')),
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customer_addresses_customer_id ON customer_addresses(customer_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_brand_id ON products(brand_id);
CREATE INDEX idx_product_prices_product_id ON product_prices(product_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);
CREATE INDEX idx_inventory_warehouse_id ON inventory(warehouse_id);
CREATE INDEX idx_purchase_orders_supplier_id ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_order_items_po_id ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_shipments_order_id ON shipments(order_id);
CREATE INDEX idx_shipment_events_shipment_id ON shipment_events(shipment_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_support_tickets_customer_id ON support_tickets(customer_id);
CREATE INDEX idx_support_ticket_messages_ticket_id ON support_ticket_messages(ticket_id);

CREATE SCHEMA analytics;
CREATE SCHEMA operations;
CREATE SCHEMA crm;

CREATE TABLE analytics.daily_sales_summary (
  summary_date DATE PRIMARY KEY,
  orders_count INTEGER NOT NULL CHECK (orders_count >= 0),
  gross_revenue NUMERIC(12, 2) NOT NULL CHECK (gross_revenue >= 0),
  refunds_total NUMERIC(12, 2) NOT NULL CHECK (refunds_total >= 0),
  new_customers INTEGER NOT NULL CHECK (new_customers >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE analytics.product_performance_snapshot (
  snapshot_date DATE NOT NULL,
  product_id BIGINT NOT NULL REFERENCES public.products(id),
  units_sold INTEGER NOT NULL CHECK (units_sold >= 0),
  gross_revenue NUMERIC(12, 2) NOT NULL CHECK (gross_revenue >= 0),
  average_rating NUMERIC(3, 2),
  PRIMARY KEY (snapshot_date, product_id)
);

CREATE TABLE operations.integration_endpoints (
  id BIGSERIAL PRIMARY KEY,
  system_name TEXT NOT NULL UNIQUE,
  base_url TEXT NOT NULL,
  owner_team TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'degraded', 'paused')),
  last_checked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE operations.job_runs (
  id BIGSERIAL PRIMARY KEY,
  job_name TEXT NOT NULL,
  environment TEXT NOT NULL CHECK (environment IN ('staging', 'production')),
  status TEXT NOT NULL CHECK (status IN ('queued', 'running', 'succeeded', 'failed')),
  started_at TIMESTAMPTZ NOT NULL,
  finished_at TIMESTAMPTZ,
  triggered_by TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  CHECK (finished_at IS NULL OR finished_at >= started_at)
);

CREATE TABLE crm.account_segments (
  customer_id BIGINT PRIMARY KEY REFERENCES public.customers(id) ON DELETE CASCADE,
  lifecycle_stage TEXT NOT NULL CHECK (lifecycle_stage IN ('new', 'growth', 'retained', 'at_risk', 'churned')),
  segment_label TEXT NOT NULL,
  health_score INTEGER NOT NULL CHECK (health_score BETWEEN 0 AND 100),
  owner_name TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE crm.outreach_campaigns (
  id BIGSERIAL PRIMARY KEY,
  campaign_name TEXT NOT NULL UNIQUE,
  channel TEXT NOT NULL CHECK (channel IN ('email', 'sms', 'support')),
  status TEXT NOT NULL CHECK (status IN ('draft', 'scheduled', 'running', 'completed')),
  target_segment TEXT NOT NULL,
  launched_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_analytics_product_performance_product_id
  ON analytics.product_performance_snapshot(product_id);
CREATE INDEX idx_operations_job_runs_job_name
  ON operations.job_runs(job_name);
CREATE INDEX idx_operations_job_runs_status
  ON operations.job_runs(status);
CREATE INDEX idx_crm_account_segments_lifecycle_stage
  ON crm.account_segments(lifecycle_stage);
