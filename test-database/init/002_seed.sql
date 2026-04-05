SELECT setseed(0.4242);

CREATE OR REPLACE FUNCTION pick_text(options TEXT[])
RETURNS TEXT
LANGUAGE sql
VOLATILE
AS $$
  SELECT options[1 + FLOOR(random() * array_length(options, 1))::INT];
$$;

INSERT INTO countries (code, name, timezone)
VALUES
  ('US', 'United States', 'America/New_York'),
  ('CA', 'Canada', 'America/Toronto'),
  ('GB', 'United Kingdom', 'Europe/London'),
  ('DE', 'Germany', 'Europe/Berlin'),
  ('FR', 'France', 'Europe/Paris'),
  ('ES', 'Spain', 'Europe/Madrid'),
  ('IT', 'Italy', 'Europe/Rome'),
  ('NL', 'Netherlands', 'Europe/Amsterdam'),
  ('SE', 'Sweden', 'Europe/Stockholm'),
  ('NO', 'Norway', 'Europe/Oslo'),
  ('JP', 'Japan', 'Asia/Tokyo'),
  ('AU', 'Australia', 'Australia/Sydney'),
  ('SG', 'Singapore', 'Asia/Singapore'),
  ('BR', 'Brazil', 'America/Sao_Paulo'),
  ('MX', 'Mexico', 'America/Mexico_City');

INSERT INTO categories (name, parent_id)
VALUES
  ('Electronics', NULL),
  ('Home & Kitchen', NULL),
  ('Fitness', NULL),
  ('Office', NULL),
  ('Fashion', NULL),
  ('Outdoors', NULL),
  ('Beauty', NULL),
  ('Pet Supplies', NULL);

INSERT INTO categories (name, parent_id)
SELECT 'Laptops', id FROM categories WHERE name = 'Electronics'
UNION ALL
SELECT 'Headphones', id FROM categories WHERE name = 'Electronics'
UNION ALL
SELECT 'Smart Home', id FROM categories WHERE name = 'Electronics'
UNION ALL
SELECT 'Cookware', id FROM categories WHERE name = 'Home & Kitchen'
UNION ALL
SELECT 'Furniture', id FROM categories WHERE name = 'Home & Kitchen'
UNION ALL
SELECT 'Cardio Equipment', id FROM categories WHERE name = 'Fitness'
UNION ALL
SELECT 'Strength Training', id FROM categories WHERE name = 'Fitness'
UNION ALL
SELECT 'Backpacks', id FROM categories WHERE name = 'Outdoors'
UNION ALL
SELECT 'Skin Care', id FROM categories WHERE name = 'Beauty'
UNION ALL
SELECT 'Dog Care', id FROM categories WHERE name = 'Pet Supplies';

WITH brand_names AS (
  SELECT unnest(ARRAY[
    'Northlight', 'Oakwell', 'Velora', 'ApexOne', 'Streamline', 'Brightforge', 'Skylark',
    'Evermode', 'Copperhill', 'Mercury Labs', 'Wavecraft', 'Bluehaven', 'Pioneer Prime',
    'Urban Crest', 'Moonfield', 'Greenline', 'Vertex Gear', 'NovaNest', 'Altura', 'Silverline',
    'Palisade', 'Truehaven', 'Westpoint', 'Cinder & Co', 'Eastbay', 'Orchid Lane',
    'Peakline', 'Granite House', 'Lumen Works', 'Harborline', 'Arbor Peak', 'Hearthway',
    'Cloudstep', 'Emberwood', 'RapidArc', 'Fable Home', 'Brookfield', 'Horizon Plus',
    'CircuitMotive', 'Atlas Goods'
  ]) AS name
)
INSERT INTO brands (name, headquarters_country_id)
SELECT name, (1 + FLOOR(random() * 15))::BIGINT
FROM brand_names;

WITH seed AS (
  SELECT
    ARRAY[
      'Liam','Noah','Oliver','Elijah','James','William','Benjamin','Lucas','Henry','Alexander',
      'Mason','Michael','Daniel','Jackson','Sebastian','Aiden','Matthew','Samuel','David','Joseph',
      'Emma','Olivia','Ava','Sophia','Isabella','Mia','Charlotte','Amelia','Harper','Evelyn',
      'Abigail','Emily','Ella','Elizabeth','Camila','Luna','Sofia','Avery','Scarlett','Grace'
    ] AS first_names,
    ARRAY[
      'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
      'Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin',
      'Lee','Perez','Thompson','White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson',
      'Walker','Young','Allen','King','Wright','Scott','Torres','Nguyen','Hill','Flores'
    ] AS last_names,
    ARRAY['gmail.com','outlook.com','hotmail.com','icloud.com','proton.me','yahoo.com'] AS email_domains,
    ARRAY['212','213','305','312','347','404','415','510','617','646','702','718','737','786','917'] AS area_codes
)
INSERT INTO customers (
  first_name,
  last_name,
  email,
  phone,
  birth_date,
  marketing_opt_in,
  status,
  created_at,
  updated_at
)
SELECT
  n.first_name,
  n.last_name,
  lower(format('%s.%s%04s@%s', n.first_name, n.last_name, g, pick_text(seed.email_domains))),
  format('+1-%s-%03s-%04s', pick_text(seed.area_codes), (100 + FLOOR(random() * 900))::INT, (1000 + FLOOR(random() * 9000))::INT),
  DATE '1955-01-01' + (FLOOR(random() * 18600))::INT,
  random() < 0.58,
  CASE
    WHEN random() < 0.92 THEN 'active'
    WHEN random() < 0.985 THEN 'inactive'
    ELSE 'suspended'
  END,
  NOW() - make_interval(days => (FLOOR(random() * 1200))::INT, hours => (FLOOR(random() * 24))::INT),
  NOW() - make_interval(days => (FLOOR(random() * 90))::INT)
FROM generate_series(1, 6000) AS g
CROSS JOIN seed
CROSS JOIN LATERAL (
  SELECT
    pick_text(seed.first_names) AS first_name,
    pick_text(seed.last_names) AS last_name
) AS n;

WITH seed AS (
  SELECT
    ARRAY['home','work','family','billing'] AS labels,
    ARRAY['Maple','Oak','Pine','Cedar','River','Lake','Hill','Sunset','Park','Main','Elm','Willow','Cherry','Forest','View'] AS street_names,
    ARRAY['St','Ave','Blvd','Rd','Ln','Way','Dr','Ct'] AS street_types,
    ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix','San Diego','Austin','Seattle','Boston','Denver','Miami','Nashville','Portland','Atlanta','Dallas'] AS cities,
    ARRAY['NY','CA','IL','TX','AZ','WA','MA','CO','FL','TN','OR','GA'] AS regions,
    (SELECT id FROM countries WHERE code = 'US') AS us_id
)
INSERT INTO customer_addresses (
  customer_id,
  label,
  line_1,
  line_2,
  city,
  region,
  postal_code,
  country_id,
  is_default,
  created_at,
  updated_at
)
SELECT
  c.id,
  CASE
    WHEN a.idx = 1 THEN 'home'
    ELSE pick_text(seed.labels)
  END,
  format('%s %s %s', (10 + FLOOR(random() * 9990))::INT, pick_text(seed.street_names), pick_text(seed.street_types)),
  CASE
    WHEN random() < 0.24 THEN format('Apt %s', (1 + FLOOR(random() * 45))::INT)
    ELSE NULL
  END,
  pick_text(seed.cities),
  pick_text(seed.regions),
  lpad((10000 + FLOOR(random() * 89999))::INT::TEXT, 5, '0'),
  CASE
    WHEN random() < 0.85 THEN seed.us_id
    ELSE (1 + FLOOR(random() * 15))::BIGINT
  END,
  a.idx = 1,
  c.created_at + make_interval(days => (FLOOR(random() * 60))::INT),
  NOW() - make_interval(days => (FLOOR(random() * 30))::INT)
FROM customers AS c
CROSS JOIN seed
CROSS JOIN LATERAL generate_series(1, 3) AS a(idx)
WHERE a.idx = 1 OR random() < 0.58;

WITH limits AS (
  SELECT
    (SELECT max(id) FROM categories) AS max_category_id,
    (SELECT max(id) FROM brands) AS max_brand_id
),
seed AS (
  SELECT
    ARRAY['Ultra','Pro','Lite','Smart','Prime','Essential','Flex','Core','Air','Max','Plus','Eco','Nimbus','Vertex','Pulse'] AS adjectives,
    ARRAY['Carbon','Steel','Alloy','Bamboo','Cotton','Leather','Ceramic','Titanium','Graphene','Silicone','Oak','Walnut'] AS materials,
    ARRAY['Speaker','Desk Lamp','Backpack','Mixer','Water Bottle','Keyboard','Mouse','Chair','Monitor Stand','Yoga Mat','Blender','Jacket','Cook Set','Headset','Air Purifier'] AS items
)
INSERT INTO products (
  sku,
  category_id,
  brand_id,
  name,
  description,
  base_price,
  weight_grams,
  status,
  created_at,
  updated_at
)
SELECT
  concat('SKU-', lpad(g::TEXT, 6, '0')),
  (1 + FLOOR(random() * limits.max_category_id))::BIGINT,
  (1 + FLOOR(random() * limits.max_brand_id))::BIGINT,
  format('%s %s %s', pick_text(seed.adjectives), pick_text(seed.materials), pick_text(seed.items)),
  format(
    'Designed for everyday use with durable %s construction and balanced performance.',
    lower(pick_text(seed.materials))
  ),
  round((8 + random() * 620)::NUMERIC, 2),
  (120 + FLOOR(random() * 9800))::INT,
  CASE
    WHEN random() < 0.91 THEN 'active'
    WHEN random() < 0.97 THEN 'discontinued'
    ELSE 'draft'
  END,
  NOW() - make_interval(days => (FLOOR(random() * 760))::INT),
  NOW() - make_interval(days => (FLOOR(random() * 90))::INT)
FROM generate_series(1, 4000) AS g
CROSS JOIN limits
CROSS JOIN seed;

INSERT INTO product_prices (product_id, price, currency, effective_from, effective_to)
SELECT
  p.id,
  round((p.base_price * (0.90 + random() * 0.18))::NUMERIC, 2),
  'USD',
  p.created_at,
  NULL
FROM products AS p;

INSERT INTO product_prices (product_id, price, currency, effective_from, effective_to)
SELECT
  p.id,
  round((p.base_price * (0.72 + random() * 0.20))::NUMERIC, 2),
  'USD',
  p.created_at - make_interval(days => (60 + FLOOR(random() * 220))::INT),
  p.created_at - make_interval(days => 1)
FROM products AS p
WHERE random() < 0.42;

INSERT INTO warehouses (code, name, city, region, country_id)
VALUES
  ('WH-NY-01', 'Northeast Fulfillment', 'New York', 'NY', (SELECT id FROM countries WHERE code = 'US')),
  ('WH-CA-01', 'West Coast Fulfillment', 'Los Angeles', 'CA', (SELECT id FROM countries WHERE code = 'US')),
  ('WH-TX-01', 'Central Fulfillment', 'Dallas', 'TX', (SELECT id FROM countries WHERE code = 'US')),
  ('WH-IL-01', 'Midwest Fulfillment', 'Chicago', 'IL', (SELECT id FROM countries WHERE code = 'US')),
  ('WH-FL-01', 'Southeast Fulfillment', 'Miami', 'FL', (SELECT id FROM countries WHERE code = 'US')),
  ('WH-WA-01', 'Pacific Northwest Fulfillment', 'Seattle', 'WA', (SELECT id FROM countries WHERE code = 'US')),
  ('WH-ON-01', 'Canada Fulfillment', 'Toronto', 'ON', (SELECT id FROM countries WHERE code = 'CA')),
  ('WH-NL-01', 'EU Fulfillment', 'Amsterdam', 'NH', (SELECT id FROM countries WHERE code = 'NL'));

INSERT INTO inventory (
  product_id,
  warehouse_id,
  on_hand_qty,
  reserved_qty,
  reorder_point,
  updated_at
)
SELECT
  p.id,
  w.id,
  (20 + FLOOR(random() * 900))::INT,
  FLOOR(random() * 80)::INT,
  (10 + FLOOR(random() * 90))::INT,
  NOW() - make_interval(days => (FLOOR(random() * 14))::INT)
FROM products AS p
JOIN LATERAL (
  SELECT id
  FROM warehouses
  ORDER BY random()
  LIMIT (1 + FLOOR(random() * 3))::INT
) AS w ON TRUE
ON CONFLICT (product_id, warehouse_id) DO NOTHING;

WITH seed AS (
  SELECT
    ARRAY['Global','Prime','North','Summit','Atlas','Evergreen','Blue','Pioneer','Metro','Continental','Pacific','Sterling','Vertex','Golden','Harbor','Lighthouse'] AS prefixes,
    ARRAY['Components','Industrial','Merchants','Sourcing','Supplies','Partners','Trading','Logistics','Networks','Wholesale','Systems','Distributors','Dynamics','Procurement'] AS nouns,
    ARRAY['Group','Co','Ltd','Inc'] AS suffixes
)
INSERT INTO suppliers (name, contact_name, contact_email, country_id, lead_time_days)
SELECT
  format(
    '%s %s %s %s',
    seed.prefixes[1 + ((g * 7) % array_length(seed.prefixes, 1))],
    seed.nouns[1 + ((g * 11) % array_length(seed.nouns, 1))],
    seed.suffixes[1 + ((g * 13) % array_length(seed.suffixes, 1))],
    to_char(g, 'FM000')
  ),
  format('%s %s', pick_text(ARRAY['Alex','Jordan','Taylor','Morgan','Casey','Riley','Jamie','Quinn']), pick_text(ARRAY['Parker','Hayes','Brooks','Reed','Campbell','Adams','Perry','Foster'])),
  lower(format('vendor%s@b2bmail.com', g)),
  (1 + FLOOR(random() * 15))::BIGINT,
  (5 + FLOOR(random() * 30))::INT
FROM generate_series(1, 180) AS g
CROSS JOIN seed;

WITH limits AS (
  SELECT
    (SELECT max(id) FROM suppliers) AS max_supplier_id,
    (SELECT max(id) FROM warehouses) AS max_warehouse_id
)
INSERT INTO purchase_orders (
  po_number,
  supplier_id,
  warehouse_id,
  status,
  ordered_at,
  expected_at,
  received_at,
  created_at,
  updated_at
)
SELECT
  concat('PO-', lpad(g::TEXT, 7, '0')),
  (1 + FLOOR(random() * limits.max_supplier_id))::BIGINT,
  (1 + FLOOR(random() * limits.max_warehouse_id))::BIGINT,
  po_status,
  ordered_at,
  ordered_at + make_interval(days => (7 + FLOOR(random() * 28))::INT),
  CASE
    WHEN po_status = 'received' THEN ordered_at + make_interval(days => (8 + FLOOR(random() * 30))::INT)
    ELSE NULL
  END,
  ordered_at,
  NOW() - make_interval(days => (FLOOR(random() * 15))::INT)
FROM generate_series(1, 2200) AS g
CROSS JOIN limits
CROSS JOIN LATERAL (
  SELECT NOW() - make_interval(days => (FLOOR(random() * 540))::INT) AS ordered_at
  WHERE g IS NOT NULL
) AS d
CROSS JOIN LATERAL (
  SELECT CASE
    WHEN random() < 0.08 THEN 'cancelled'
    WHEN random() < 0.18 THEN 'draft'
    WHEN random() < 0.36 THEN 'submitted'
    WHEN random() < 0.68 THEN 'shipped'
    ELSE 'received'
  END AS po_status
  WHERE g IS NOT NULL
) AS s;

INSERT INTO purchase_order_items (
  purchase_order_id,
  product_id,
  quantity_ordered,
  quantity_received,
  unit_cost
)
SELECT
  po.id,
  p.id,
  q.qty_ordered,
  CASE
    WHEN po.status = 'received' THEN q.qty_ordered
    WHEN po.status = 'shipped' THEN FLOOR(q.qty_ordered * (0.55 + random() * 0.45))::INT
    ELSE 0
  END,
  round((p.base_price * (0.42 + random() * 0.35))::NUMERIC, 2)
FROM purchase_orders AS po
JOIN LATERAL generate_series(1, 6) AS li(n) ON TRUE
JOIN LATERAL (
  SELECT id, base_price
  FROM products
  ORDER BY random()
  LIMIT 1
) AS p ON TRUE
CROSS JOIN LATERAL (
  SELECT (8 + FLOOR(random() * 220))::INT AS qty_ordered
) AS q
WHERE li.n = 1 OR random() < 0.52
ON CONFLICT (purchase_order_id, product_id) DO NOTHING;

WITH limits AS (
  SELECT (SELECT max(id) FROM customers) AS max_customer_id
),
channels AS (
  SELECT ARRAY['web','ios','android','support'] AS values
)
INSERT INTO orders (
  order_number,
  customer_id,
  shipping_address_id,
  billing_address_id,
  status,
  source_channel,
  currency,
  placed_at,
  paid_at,
  cancelled_at,
  created_at,
  updated_at
)
SELECT
  concat('ORD-', lpad(g::TEXT, 8, '0')),
  c.customer_id,
  ship.id,
  bill.id,
  st.status,
  pick_text(channels.values),
  'USD',
  ts.placed_at,
  CASE
    WHEN st.status IN ('paid', 'shipped', 'delivered', 'refunded')
      THEN ts.placed_at + make_interval(hours => (1 + FLOOR(random() * 72))::INT)
    ELSE NULL
  END,
  CASE
    WHEN st.status = 'cancelled'
      THEN ts.placed_at + make_interval(hours => (2 + FLOOR(random() * 48))::INT)
    ELSE NULL
  END,
  ts.placed_at,
  NOW() - make_interval(days => (FLOOR(random() * 7))::INT)
FROM generate_series(1, 18000) AS g
CROSS JOIN limits
CROSS JOIN channels
CROSS JOIN LATERAL (
  SELECT (1 + FLOOR(random() * limits.max_customer_id))::BIGINT AS customer_id
  WHERE g IS NOT NULL
) AS c
LEFT JOIN LATERAL (
  SELECT id
  FROM customer_addresses
  WHERE customer_id = c.customer_id
  ORDER BY random()
  LIMIT 1
) AS ship ON TRUE
LEFT JOIN LATERAL (
  SELECT id
  FROM customer_addresses
  WHERE customer_id = c.customer_id
  ORDER BY random()
  LIMIT 1
) AS bill ON TRUE
CROSS JOIN LATERAL (
  SELECT NOW() - make_interval(days => (FLOOR(random() * 365))::INT, hours => (FLOOR(random() * 24))::INT) AS placed_at
  WHERE g IS NOT NULL
) AS ts
CROSS JOIN LATERAL (
  SELECT random() AS r
  WHERE g IS NOT NULL
) AS rv
CROSS JOIN LATERAL (
  SELECT CASE
    WHEN rv.r < 0.08 THEN 'cancelled'
    WHEN rv.r < 0.20 THEN 'pending_payment'
    WHEN rv.r < 0.45 THEN 'paid'
    WHEN rv.r < 0.72 THEN 'shipped'
    WHEN rv.r < 0.95 THEN 'delivered'
    ELSE 'refunded'
  END AS status
) AS st;

INSERT INTO order_items (
  order_id,
  product_id,
  quantity,
  unit_price,
  discount_pct,
  line_total
)
SELECT
  o.id,
  p.id,
  calc.qty,
  calc.unit_price,
  calc.discount_pct,
  round((calc.qty * calc.unit_price * (1 - calc.discount_pct))::NUMERIC, 2)
FROM orders AS o
JOIN LATERAL generate_series(1, 5) AS li(n) ON TRUE
JOIN LATERAL (
  SELECT id, base_price
  FROM products
  WHERE status = 'active'
  ORDER BY random()
  LIMIT 1
) AS p ON TRUE
CROSS JOIN LATERAL (
  SELECT
    (1 + FLOOR(random() * 4))::INT AS qty,
    round((p.base_price * (0.84 + random() * 0.35))::NUMERIC, 2) AS unit_price,
    CASE
      WHEN random() < 0.28 THEN round((0.03 + random() * 0.24)::NUMERIC, 4)
      ELSE 0::NUMERIC
    END AS discount_pct
) AS calc
WHERE li.n = 1 OR random() < 0.62;

WITH line_totals AS (
  SELECT
    oi.order_id,
    round(sum(oi.line_total)::NUMERIC, 2) AS subtotal
  FROM order_items AS oi
  GROUP BY oi.order_id
),
factors AS (
  SELECT
    lt.order_id,
    lt.subtotal,
    round((random() * 0.12)::NUMERIC, 4) AS discount_rate,
    round((4 + random() * 18)::NUMERIC, 2) AS shipping_cost
  FROM line_totals AS lt
)
UPDATE orders AS o
SET
  subtotal = f.subtotal,
  discount_total = CASE
    WHEN o.status = 'cancelled' THEN 0
    ELSE round((f.subtotal * f.discount_rate)::NUMERIC, 2)
  END,
  shipping_total = CASE
    WHEN o.status = 'cancelled' THEN 0
    ELSE f.shipping_cost
  END,
  tax_total = CASE
    WHEN o.status = 'cancelled' THEN 0
    ELSE round(((f.subtotal - (f.subtotal * f.discount_rate)) * 0.08)::NUMERIC, 2)
  END,
  total = CASE
    WHEN o.status = 'cancelled' THEN 0
    ELSE round(((f.subtotal - (f.subtotal * f.discount_rate)) * 1.08 + f.shipping_cost)::NUMERIC, 2)
  END
FROM factors AS f
WHERE o.id = f.order_id;

WITH providers AS (
  SELECT ARRAY['stripe','adyen','braintree','checkout'] AS values
),
methods AS (
  SELECT ARRAY['card','paypal','apple_pay','google_pay','bank_transfer'] AS values
)
INSERT INTO payments (
  order_id,
  provider,
  payment_method,
  status,
  amount,
  transaction_ref,
  paid_at
)
SELECT
  o.id,
  pick_text(providers.values),
  pick_text(methods.values),
  CASE
    WHEN o.status = 'pending_payment' THEN pick_text(ARRAY['pending','failed'])
    WHEN o.status = 'refunded' THEN 'refunded'
    WHEN random() < 0.92 THEN 'captured'
    ELSE 'authorized'
  END,
  CASE
    WHEN o.status = 'pending_payment' THEN round((o.total * (0.20 + random() * 0.80))::NUMERIC, 2)
    ELSE o.total
  END,
  format('TX-%s-%s', o.id, substring(md5(random()::TEXT), 1, 10)),
  CASE
    WHEN o.status IN ('paid', 'shipped', 'delivered', 'refunded') THEN o.paid_at
    ELSE NULL
  END
FROM orders AS o
CROSS JOIN providers
CROSS JOIN methods
WHERE o.status <> 'cancelled';

WITH limits AS (
  SELECT (SELECT max(id) FROM warehouses) AS max_warehouse_id
),
carriers AS (
  SELECT ARRAY['UPS','FedEx','USPS','DHL','OnTrac','Royal Mail'] AS values
),
levels AS (
  SELECT ARRAY['ground','two_day','overnight','economy'] AS values
),
src AS (
  SELECT
    o.id AS order_id,
    (1 + FLOOR(random() * limits.max_warehouse_id))::BIGINT AS warehouse_id,
    pick_text(carriers.values) AS carrier,
    pick_text(levels.values) AS service_level,
    o.status AS order_status,
    o.placed_at + make_interval(days => (1 + FLOOR(random() * 4))::INT) AS shipped_at
  FROM orders AS o
  CROSS JOIN limits
  CROSS JOIN carriers
  CROSS JOIN levels
  WHERE o.status IN ('shipped', 'delivered', 'refunded')
)
INSERT INTO shipments (
  order_id,
  warehouse_id,
  carrier,
  service_level,
  tracking_number,
  status,
  shipped_at,
  delivered_at
)
SELECT
  s.order_id,
  s.warehouse_id,
  s.carrier,
  s.service_level,
  format('TRK-%s-%s', s.order_id, substring(md5(random()::TEXT), 1, 8)),
  CASE
    WHEN s.order_status = 'shipped' THEN 'in_transit'
    WHEN s.order_status = 'refunded' AND random() < 0.18 THEN 'returned'
    ELSE 'delivered'
  END,
  s.shipped_at,
  CASE
    WHEN s.order_status = 'shipped' THEN NULL
    ELSE s.shipped_at + make_interval(days => (1 + FLOOR(random() * 6))::INT)
  END
FROM src AS s;

INSERT INTO shipment_events (shipment_id, status, location, event_time, details)
SELECT
  s.id,
  'label_created',
  w.city,
  COALESCE(s.shipped_at, s.created_at) - INTERVAL '8 hours',
  'Shipping label generated'
FROM shipments AS s
JOIN warehouses AS w ON w.id = s.warehouse_id;

INSERT INTO shipment_events (shipment_id, status, location, event_time, details)
SELECT
  s.id,
  'in_transit',
  w.city,
  COALESCE(s.shipped_at, s.created_at) + INTERVAL '1 day',
  'Package departed local facility'
FROM shipments AS s
JOIN warehouses AS w ON w.id = s.warehouse_id;

INSERT INTO shipment_events (shipment_id, status, location, event_time, details)
SELECT
  s.id,
  CASE WHEN s.status = 'returned' THEN 'returned' ELSE 'delivered' END,
  pick_text(ARRAY['Customer Address','Local Hub','Pickup Point']),
  COALESCE(s.delivered_at, s.shipped_at + INTERVAL '3 days'),
  CASE WHEN s.status = 'returned' THEN 'Delivery issue, package returned' ELSE 'Delivered to recipient' END
FROM shipments AS s
WHERE s.status IN ('delivered', 'returned');

WITH seed AS (
  SELECT
    ARRAY['Excellent value','Exactly as described','Very reliable','Solid quality','Great purchase','Exceeded expectations'] AS titles,
    ARRAY[
      'Build quality is better than expected and setup was straightforward.',
      'Delivery was quick and the product performs consistently.',
      'Packaging was secure and the item feels premium for the price.',
      'Good balance between price and performance, would buy again.',
      'Works well in daily use and customer support was responsive.',
      'After a few weeks of use, still very satisfied with the purchase.'
    ] AS bodies
)
INSERT INTO reviews (
  customer_id,
  product_id,
  order_item_id,
  rating,
  title,
  body,
  verified_purchase,
  created_at
)
SELECT
  o.customer_id,
  oi.product_id,
  oi.id,
  CASE
    WHEN random() < 0.55 THEN 5
    WHEN random() < 0.82 THEN 4
    WHEN random() < 0.94 THEN 3
    WHEN random() < 0.985 THEN 2
    ELSE 1
  END,
  pick_text(seed.titles),
  pick_text(seed.bodies),
  TRUE,
  o.placed_at + make_interval(days => (4 + FLOOR(random() * 45))::INT)
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.id
CROSS JOIN seed
WHERE o.status IN ('delivered', 'refunded')
  AND random() < 0.24
ON CONFLICT (customer_id, product_id, order_item_id) DO NOTHING;

WITH limits AS (
  SELECT (SELECT max(id) FROM customers) AS max_customer_id
),
seed AS (
  SELECT ARRAY[
    'Where is my order?', 'Requesting a return', 'Payment issue', 'Wrong item received',
    'Need invoice copy', 'Product arrived damaged', 'Can I change shipping address?',
    'Missing accessory in box', 'Warranty claim question', 'Order cancellation request'
  ] AS subjects
)
INSERT INTO support_tickets (
  ticket_number,
  customer_id,
  order_id,
  subject,
  status,
  priority,
  created_at,
  resolved_at
)
SELECT
  concat('TKT-', lpad(g::TEXT, 7, '0')),
  c.customer_id,
  co.id,
  pick_text(seed.subjects),
  st.status,
  pr.priority,
  ts.created_at,
  CASE
    WHEN st.status IN ('resolved', 'closed')
      THEN ts.created_at + make_interval(hours => (3 + FLOOR(random() * 96))::INT)
    ELSE NULL
  END
FROM generate_series(1, 3500) AS g
CROSS JOIN limits
CROSS JOIN seed
CROSS JOIN LATERAL (
  SELECT (1 + FLOOR(random() * limits.max_customer_id))::BIGINT AS customer_id
  WHERE g IS NOT NULL
) AS c
LEFT JOIN LATERAL (
  SELECT id
  FROM orders
  WHERE customer_id = c.customer_id
  ORDER BY random()
  LIMIT 1
) AS co ON TRUE
CROSS JOIN LATERAL (
  SELECT NOW() - make_interval(days => (FLOOR(random() * 220))::INT, hours => (FLOOR(random() * 24))::INT) AS created_at
  WHERE g IS NOT NULL
) AS ts
CROSS JOIN LATERAL (
  SELECT random() AS r
  WHERE g IS NOT NULL
) AS rv
CROSS JOIN LATERAL (
  SELECT CASE
    WHEN rv.r < 0.28 THEN 'open'
    WHEN rv.r < 0.51 THEN 'pending_customer'
    WHEN rv.r < 0.83 THEN 'resolved'
    ELSE 'closed'
  END AS status
) AS st
CROSS JOIN LATERAL (
  SELECT CASE
    WHEN random() < 0.08 THEN 'urgent'
    WHEN random() < 0.30 THEN 'high'
    WHEN random() < 0.78 THEN 'normal'
    ELSE 'low'
  END AS priority
) AS pr;

INSERT INTO support_ticket_messages (ticket_id, author_role, body, created_at)
SELECT
  t.id,
  CASE
    WHEN msg.idx % 2 = 1 THEN 'customer'
    ELSE 'agent'
  END,
  CASE
    WHEN msg.idx % 2 = 1 THEN pick_text(ARRAY[
      'Hi, I need help with this order.',
      'Can you check the latest status for me?',
      'I attached details in my previous message.',
      'I still have not received an update.',
      'Please let me know the next steps.'
    ])
    ELSE pick_text(ARRAY[
      'Thanks for reaching out. I am checking this now.',
      'I reviewed your account and shared an update above.',
      'We have escalated this to our fulfillment team.',
      'I have issued a follow-up action and will confirm shortly.',
      'This has been logged and we will keep you posted.'
    ])
  END,
  t.created_at + make_interval(hours => (msg.idx * (1 + FLOOR(random() * 20))::INT))
FROM support_tickets AS t
JOIN LATERAL generate_series(1, 6) AS msg(idx) ON TRUE
WHERE msg.idx <= 2 OR random() < 0.46;

INSERT INTO support_ticket_messages (ticket_id, author_role, body, created_at)
SELECT
  t.id,
  'system',
  'Ticket status changed to resolved.',
  t.resolved_at
FROM support_tickets AS t
WHERE t.status IN ('resolved', 'closed')
  AND t.resolved_at IS NOT NULL;

INSERT INTO analytics.daily_sales_summary (
  summary_date,
  orders_count,
  gross_revenue,
  refunds_total,
  new_customers
)
SELECT
  day.day::DATE AS summary_date,
  COUNT(o.id)::INT AS orders_count,
  COALESCE(round(SUM(o.total), 2), 0)::NUMERIC(12, 2) AS gross_revenue,
  COALESCE(round(SUM(CASE WHEN o.status = 'refunded' THEN o.total ELSE 0 END), 2), 0)::NUMERIC(12, 2) AS refunds_total,
  (
    SELECT COUNT(*)::INT
    FROM customers AS c
    WHERE c.created_at::DATE = day.day::DATE
  ) AS new_customers
FROM generate_series(CURRENT_DATE - INTERVAL '29 days', CURRENT_DATE, INTERVAL '1 day') AS day(day)
LEFT JOIN orders AS o
  ON o.placed_at::DATE = day.day::DATE
GROUP BY day.day
ORDER BY day.day;

WITH ranked_products AS (
  SELECT
    oi.product_id,
    SUM(oi.quantity)::INT AS units_sold,
    round(SUM(oi.line_total), 2)::NUMERIC(12, 2) AS gross_revenue,
    round(AVG(r.rating), 2)::NUMERIC(3, 2) AS average_rating,
    ROW_NUMBER() OVER (
      ORDER BY SUM(oi.line_total) DESC, oi.product_id
    ) AS revenue_rank
  FROM order_items AS oi
  LEFT JOIN reviews AS r
    ON r.order_item_id = oi.id
  GROUP BY oi.product_id
),
snapshot_dates AS (
  SELECT CURRENT_DATE - 1 AS snapshot_date
  UNION ALL
  SELECT CURRENT_DATE - 7 AS snapshot_date
)
INSERT INTO analytics.product_performance_snapshot (
  snapshot_date,
  product_id,
  units_sold,
  gross_revenue,
  average_rating
)
SELECT
  sd.snapshot_date,
  rp.product_id,
  rp.units_sold,
  rp.gross_revenue,
  rp.average_rating
FROM snapshot_dates AS sd
JOIN ranked_products AS rp
  ON rp.revenue_rank <= 25
ORDER BY sd.snapshot_date, rp.revenue_rank;

INSERT INTO operations.integration_endpoints (
  system_name,
  base_url,
  owner_team,
  status,
  last_checked_at
)
VALUES
  ('stripe', 'https://api.stripe.example.internal', 'payments', 'active', NOW() - INTERVAL '8 minutes'),
  ('shippo', 'https://shippo.example.internal', 'fulfillment', 'active', NOW() - INTERVAL '11 minutes'),
  ('zendesk', 'https://zendesk.example.internal', 'support', 'degraded', NOW() - INTERVAL '21 minutes'),
  ('netsuite', 'https://netsuite.example.internal', 'finance', 'paused', NOW() - INTERVAL '2 hours');

WITH seed AS (
  SELECT
    ARRAY['nightly-etl', 'inventory-sync', 'fraud-check', 'refund-reconciliation', 'warehouse-rollup'] AS job_names,
    ARRAY['scheduler', 'support-console', 'ops-dashboard', 'backfill-script'] AS triggers
)
INSERT INTO operations.job_runs (
  job_name,
  environment,
  status,
  started_at,
  finished_at,
  triggered_by,
  details
)
SELECT
  pick_text(seed.job_names),
  CASE
    WHEN random() < 0.18 THEN 'staging'
    ELSE 'production'
  END,
  run_status.status,
  run_times.started_at,
  CASE
    WHEN run_status.status IN ('queued', 'running') THEN NULL
    ELSE run_times.started_at + make_interval(minutes => (5 + FLOOR(random() * 90))::INT)
  END,
  pick_text(seed.triggers),
  jsonb_build_object(
    'attempt', (1 + FLOOR(random() * 3))::INT,
    'region', pick_text(ARRAY['us-east-1', 'us-west-2', 'eu-west-1']),
    'batch_size', (50 + FLOOR(random() * 950))::INT
  )
FROM generate_series(1, 80) AS g
CROSS JOIN seed
CROSS JOIN LATERAL (
  SELECT NOW() - make_interval(days => (FLOOR(random() * 20))::INT, hours => (FLOOR(random() * 24))::INT) AS started_at
) AS run_times
CROSS JOIN LATERAL (
  SELECT CASE
    WHEN random() < 0.10 THEN 'queued'
    WHEN random() < 0.24 THEN 'running'
    WHEN random() < 0.90 THEN 'succeeded'
    ELSE 'failed'
  END AS status
) AS run_status;

WITH customer_order_stats AS (
  SELECT
    c.id AS customer_id,
    COUNT(o.id)::INT AS orders_count,
    MAX(o.placed_at) AS last_order_at,
    COALESCE(SUM(o.total), 0)::NUMERIC(12, 2) AS lifetime_value
  FROM customers AS c
  LEFT JOIN orders AS o
    ON o.customer_id = c.id
  GROUP BY c.id
),
seed AS (
  SELECT ARRAY['Avery Cole', 'Jordan Lee', 'Mina Patel', 'Theo Brooks', 'Sam Rivera'] AS owners
)
INSERT INTO crm.account_segments (
  customer_id,
  lifecycle_stage,
  segment_label,
  health_score,
  owner_name
)
SELECT
  stats.customer_id,
  CASE
    WHEN stats.orders_count = 0 THEN 'new'
    WHEN stats.last_order_at IS NULL OR stats.last_order_at < NOW() - INTERVAL '240 days' THEN 'churned'
    WHEN stats.last_order_at < NOW() - INTERVAL '120 days' THEN 'at_risk'
    WHEN stats.orders_count >= 6 THEN 'retained'
    ELSE 'growth'
  END AS lifecycle_stage,
  CASE
    WHEN stats.orders_count = 0 THEN 'never-purchased'
    WHEN stats.lifetime_value >= 2500 THEN 'vip-repeat'
    WHEN stats.last_order_at < NOW() - INTERVAL '120 days' THEN 'win-back'
    WHEN stats.orders_count >= 3 THEN 'steady-repeat'
    ELSE 'early-repeat'
  END AS segment_label,
  GREATEST(
    5,
    LEAST(
      100,
      25
        + LEAST(stats.orders_count * 7, 35)
        + LEAST(FLOOR(stats.lifetime_value / 150)::INT, 25)
        - CASE
            WHEN stats.last_order_at IS NULL THEN 10
            WHEN stats.last_order_at < NOW() - INTERVAL '240 days' THEN 40
            WHEN stats.last_order_at < NOW() - INTERVAL '120 days' THEN 20
            ELSE 0
          END
    )
  )::INT AS health_score,
  CASE
    WHEN random() < 0.22 THEN NULL
    ELSE pick_text(seed.owners)
  END AS owner_name
FROM customer_order_stats AS stats
CROSS JOIN seed;

INSERT INTO crm.outreach_campaigns (
  campaign_name,
  channel,
  status,
  target_segment,
  launched_at
)
VALUES
  ('Spring Winback Push', 'email', 'completed', 'win-back', NOW() - INTERVAL '21 days'),
  ('VIP Concierge Touchpoint', 'support', 'running', 'vip-repeat', NOW() - INTERVAL '3 days'),
  ('New Customer Education Drip', 'email', 'running', 'never-purchased', NOW() - INTERVAL '5 days'),
  ('SMS Checkout Recovery', 'sms', 'scheduled', 'early-repeat', NULL),
  ('Dormant Customer Check-In', 'email', 'draft', 'at-risk', NULL);

DROP FUNCTION pick_text(TEXT[]);

ANALYZE;
