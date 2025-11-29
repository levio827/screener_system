# PERF-002: CDN and Static Caching

## Metadata

| Field | Value |
|-------|-------|
| **ID** | PERF-002 |
| **Title** | Setup CDN for Static Assets |
| **Type** | Infrastructure |
| **Status** | BACKLOG |
| **Priority** | P1 (High) |
| **Estimate** | 8 hours |
| **Sprint** | Sprint 6 |
| **Epic** | Performance & Scalability |
| **Assignee** | TBD |
| **Created** | 2025-11-29 |
| **Tags** | `cdn`, `cloudfront`, `cloudflare`, `caching`, `performance`, `assets` |
| **Blocks** | - |

## Description

Implement a comprehensive CDN solution for static asset delivery using CloudFront or Cloudflare. This includes optimizing frontend build artifacts, implementing modern image formats (WebP, AVIF), setting up intelligent cache headers, configuring cache invalidation strategies, and establishing performance monitoring to ensure global content delivery optimization.

## Acceptance Criteria

- [ ] **CDN Provider Setup**
  - [ ] Choose and configure CDN provider (CloudFront or Cloudflare)
  - [ ] Setup custom domain with SSL/TLS certificates
  - [ ] Configure origin server connection
  - [ ] Setup geographic distribution and edge locations
  - [ ] Configure compression (Gzip, Brotli)
- [ ] **Frontend Build Artifacts CDN Deployment**
  - [ ] Configure build output for CDN deployment
  - [ ] Setup automatic deployment pipeline
  - [ ] Implement content hashing for cache busting
  - [ ] Configure proper cache headers
  - [ ] Setup versioned asset URLs
- [ ] **Image Optimization**
  - [ ] Implement WebP format support
  - [ ] Add AVIF format with fallback
  - [ ] Setup responsive image delivery
  - [ ] Configure image compression pipeline
  - [ ] Implement lazy loading for images
- [ ] **Cache Invalidation Strategy**
  - [ ] Implement automated invalidation on deployments
  - [ ] Setup manual invalidation process
  - [ ] Configure cache TTL policies
  - [ ] Implement versioning strategy
  - [ ] Setup purge API integration
- [ ] **Performance Monitoring**
  - [ ] Configure CDN analytics and reporting
  - [ ] Setup cache hit ratio monitoring
  - [ ] Implement edge response time tracking
  - [ ] Configure bandwidth usage alerts
  - [ ] Setup real user monitoring (RUM)

## Subtasks

### 1. CDN Provider Selection and Configuration
- [ ] **Provider Evaluation**
  - [ ] Compare CloudFront vs Cloudflare features
  - [ ] Evaluate pricing models
  - [ ] Assess geographic coverage
  - [ ] Review performance benchmarks
  - [ ] Make final provider decision
- [ ] **Initial Setup**
  - [ ] Create CDN account and distribution
  - [ ] Configure origin server settings
  - [ ] Setup SSL/TLS certificates
  - [ ] Configure custom domain (cdn.example.com)
  - [ ] Enable HTTP/2 and HTTP/3 support
- [ ] **Compression Configuration**
  - [ ] Enable Gzip compression
  - [ ] Enable Brotli compression
  - [ ] Configure compression level
  - [ ] Test compression effectiveness
- [ ] **Security Settings**
  - [ ] Enable HTTPS-only access
  - [ ] Configure CORS headers
  - [ ] Setup signed URLs (if needed)
  - [ ] Enable DDoS protection
  - [ ] Configure WAF rules

### 2. Frontend Build Artifacts Deployment
- [ ] **Build Configuration**
  - [ ] Configure Webpack/Vite for CDN deployment
  - [ ] Enable content hashing in filenames
  - [ ] Setup public path configuration
  - [ ] Configure source maps for CDN
  - [ ] Optimize bundle splitting
- [ ] **Deployment Pipeline**
  - [ ] Create CI/CD pipeline for CDN deployment
  - [ ] Setup automated upload to CDN
  - [ ] Configure deployment environments
  - [ ] Implement blue-green deployment
  - [ ] Add deployment rollback capability
- [ ] **Cache Headers Configuration**
  - [ ] Set immutable cache headers for hashed assets
  - [ ] Configure short cache for HTML files
  - [ ] Setup cache-control directives
  - [ ] Configure ETag headers
  - [ ] Test cache behavior

### 3. Image Optimization Implementation
- [ ] **Format Conversion**
  - [ ] Setup image processing pipeline
  - [ ] Implement WebP conversion
  - [ ] Add AVIF support with fallback
  - [ ] Configure format detection
  - [ ] Test browser compatibility
- [ ] **Responsive Images**
  - [ ] Generate multiple image sizes
  - [ ] Implement srcset attributes
  - [ ] Configure picture element usage
  - [ ] Setup art direction support
  - [ ] Test on various devices
- [ ] **Compression and Optimization**
  - [ ] Configure compression quality
  - [ ] Remove image metadata
  - [ ] Implement progressive JPEG
  - [ ] Optimize SVG files
  - [ ] Add image optimization to CI/CD
- [ ] **Lazy Loading**
  - [ ] Implement intersection observer
  - [ ] Add loading="lazy" attribute
  - [ ] Configure placeholder images
  - [ ] Test scroll performance
  - [ ] Measure lazy loading impact

### 4. Cache Invalidation Strategy
- [ ] **Automated Invalidation**
  - [ ] Integrate invalidation with deployment
  - [ ] Configure path-based invalidation
  - [ ] Setup wildcard invalidation rules
  - [ ] Implement version-based cache busting
  - [ ] Test invalidation timing
- [ ] **Manual Controls**
  - [ ] Create invalidation script/tool
  - [ ] Document invalidation process
  - [ ] Setup emergency purge capability
  - [ ] Add invalidation logging
  - [ ] Create invalidation dashboard
- [ ] **TTL Configuration**
  - [ ] Set appropriate TTL for each asset type
  - [ ] Configure stale-while-revalidate
  - [ ] Setup cache-control max-age
  - [ ] Implement conditional requests
  - [ ] Test TTL effectiveness

### 5. Performance Monitoring and Optimization
- [ ] **Analytics Setup**
  - [ ] Enable CDN analytics dashboard
  - [ ] Configure custom metrics
  - [ ] Setup geographic performance tracking
  - [ ] Monitor cache hit ratios
  - [ ] Track error rates
- [ ] **Alerting Configuration**
  - [ ] Setup cache hit ratio alerts
  - [ ] Configure bandwidth threshold alerts
  - [ ] Add error rate monitoring
  - [ ] Setup performance degradation alerts
  - [ ] Create incident response runbook
- [ ] **Performance Testing**
  - [ ] Conduct load testing
  - [ ] Test from multiple geographic locations
  - [ ] Measure TTFB improvement
  - [ ] Benchmark against baseline
  - [ ] Document performance gains

## Implementation Details

### CloudFront Configuration

```yaml
# cloudfront-config.yml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  CDNDistribution:
    Type: 'AWS::CloudFront::Distribution'
    Properties:
      DistributionConfig:
        Enabled: true
        Comment: 'Screener System CDN'
        Origins:
          - Id: S3Origin
            DomainName: screener-assets.s3.amazonaws.com
            S3OriginConfig:
              OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${CloudFrontOAI}'
        DefaultCacheBehavior:
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          AllowedMethods:
            - GET
            - HEAD
            - OPTIONS
          CachedMethods:
            - GET
            - HEAD
          Compress: true
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
            Headers:
              - Origin
              - Access-Control-Request-Method
              - Access-Control-Request-Headers
          MinTTL: 0
          DefaultTTL: 86400
          MaxTTL: 31536000
        CacheBehaviors:
          # Static assets with content hash
          - PathPattern: '/static/*'
            TargetOriginId: S3Origin
            ViewerProtocolPolicy: redirect-to-https
            AllowedMethods:
              - GET
              - HEAD
            CachedMethods:
              - GET
              - HEAD
            Compress: true
            MinTTL: 31536000
            DefaultTTL: 31536000
            MaxTTL: 31536000
            ForwardedValues:
              QueryString: false
              Cookies:
                Forward: none
          # HTML files - short cache
          - PathPattern: '*.html'
            TargetOriginId: S3Origin
            ViewerProtocolPolicy: redirect-to-https
            MinTTL: 0
            DefaultTTL: 300
            MaxTTL: 3600
            Compress: true
            ForwardedValues:
              QueryString: false
        ViewerCertificate:
          AcmCertificateArn: !Ref SSLCertificate
          SslSupportMethod: sni-only
          MinimumProtocolVersion: TLSv1.2_2021
        HttpVersion: http2and3
        PriceClass: PriceClass_All
        CustomErrorResponses:
          - ErrorCode: 404
            ResponseCode: 200
            ResponsePagePath: /index.html
            ErrorCachingMinTTL: 300

  CloudFrontOAI:
    Type: 'AWS::CloudFront::CloudFrontOriginAccessIdentity'
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: 'OAI for screener system'
```

### Cloudflare Configuration (Alternative)

```javascript
// cloudflare-config.js
const Cloudflare = require('cloudflare');

const cf = new Cloudflare({
  email: process.env.CLOUDFLARE_EMAIL,
  key: process.env.CLOUDFLARE_API_KEY,
});

const ZONE_ID = process.env.CLOUDFLARE_ZONE_ID;

// Page Rules Configuration
const pageRules = [
  {
    targets: [
      {
        target: 'url',
        constraint: {
          operator: 'matches',
          value: '*cdn.example.com/static/*',
        },
      },
    ],
    actions: [
      { id: 'cache_level', value: 'cache_everything' },
      { id: 'edge_cache_ttl', value: 31536000 },
      { id: 'browser_cache_ttl', value: 31536000 },
    ],
    priority: 1,
    status: 'active',
  },
  {
    targets: [
      {
        target: 'url',
        constraint: {
          operator: 'matches',
          value: '*cdn.example.com/*.html',
        },
      },
    ],
    actions: [
      { id: 'cache_level', value: 'cache_everything' },
      { id: 'edge_cache_ttl', value: 300 },
      { id: 'browser_cache_ttl', value: 300 },
    ],
    priority: 2,
    status: 'active',
  },
];

// Setup function
async function setupCloudflare() {
  // Enable Brotli compression
  await cf.zones.settings.edit(ZONE_ID, 'brotli', {
    value: 'on',
  });

  // Enable HTTP/3
  await cf.zones.settings.edit(ZONE_ID, 'http3', {
    value: 'on',
  });

  // Enable Always Use HTTPS
  await cf.zones.settings.edit(ZONE_ID, 'always_use_https', {
    value: 'on',
  });

  // Create page rules
  for (const rule of pageRules) {
    await cf.pageRules.add(ZONE_ID, rule);
  }

  console.log('Cloudflare configuration completed');
}

module.exports = { setupCloudflare };
```

### Webpack Configuration for CDN

```javascript
// webpack.config.js
const webpack = require('webpack');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CompressionPlugin = require('compression-webpack-plugin');

const CDN_URL = process.env.CDN_URL || '';
const isProduction = process.env.NODE_ENV === 'production';

module.exports = {
  mode: isProduction ? 'production' : 'development',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'static/js/[name].[contenthash:8].js',
    chunkFilename: 'static/js/[name].[contenthash:8].chunk.js',
    assetModuleFilename: 'static/media/[name].[hash][ext]',
    publicPath: isProduction ? CDN_URL : '/',
    clean: true,
  },
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          priority: -10,
        },
        common: {
          minChunks: 2,
          priority: -20,
          reuseExistingChunk: true,
        },
      },
    },
    runtimeChunk: 'single',
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({
      template: './public/index.html',
      inject: true,
      minify: isProduction ? {
        removeComments: true,
        collapseWhitespace: true,
        removeRedundantAttributes: true,
        useShortDoctype: true,
        removeEmptyAttributes: true,
        removeStyleLinkTypeAttributes: true,
        keepClosingSlash: true,
        minifyJS: true,
        minifyCSS: true,
        minifyURLs: true,
      } : false,
    }),
    new MiniCssExtractPlugin({
      filename: 'static/css/[name].[contenthash:8].css',
      chunkFilename: 'static/css/[name].[contenthash:8].chunk.css',
    }),
    // Generate Brotli and Gzip compressed versions
    new CompressionPlugin({
      filename: '[path][base].br',
      algorithm: 'brotliCompress',
      test: /\.(js|css|html|svg)$/,
      compressionOptions: {
        level: 11,
      },
      threshold: 10240,
      minRatio: 0.8,
    }),
    new CompressionPlugin({
      filename: '[path][base].gz',
      algorithm: 'gzip',
      test: /\.(js|css|html|svg)$/,
      threshold: 10240,
      minRatio: 0.8,
    }),
  ],
};
```

### Image Optimization Pipeline

```javascript
// scripts/optimize-images.js
const sharp = require('sharp');
const fs = require('fs').promises;
const path = require('path');
const glob = require('glob');

const IMAGE_SIZES = [320, 640, 960, 1280, 1920];
const IMAGE_QUALITY = {
  webp: 80,
  avif: 70,
  jpeg: 85,
};

async function optimizeImage(inputPath, outputDir) {
  const filename = path.basename(inputPath, path.extname(inputPath));
  const image = sharp(inputPath);
  const metadata = await image.metadata();

  console.log(`Processing: ${inputPath}`);

  // Generate responsive sizes
  for (const width of IMAGE_SIZES) {
    if (width > metadata.width) continue;

    // Generate WebP
    await image
      .clone()
      .resize(width)
      .webp({ quality: IMAGE_QUALITY.webp })
      .toFile(path.join(outputDir, `${filename}-${width}w.webp`));

    // Generate AVIF
    await image
      .clone()
      .resize(width)
      .avif({ quality: IMAGE_QUALITY.avif })
      .toFile(path.join(outputDir, `${filename}-${width}w.avif`));

    // Generate optimized JPEG as fallback
    await image
      .clone()
      .resize(width)
      .jpeg({ quality: IMAGE_QUALITY.jpeg, progressive: true })
      .toFile(path.join(outputDir, `${filename}-${width}w.jpg`));
  }
}

async function processAllImages() {
  const inputDir = path.join(__dirname, '../public/images');
  const outputDir = path.join(__dirname, '../dist/images');

  await fs.mkdir(outputDir, { recursive: true });

  const images = glob.sync(path.join(inputDir, '**/*.{jpg,jpeg,png}'));

  for (const image of images) {
    await optimizeImage(image, outputDir);
  }

  console.log(`Processed ${images.length} images`);
}

processAllImages().catch(console.error);
```

### Responsive Image Component

```tsx
// src/components/ResponsiveImage.tsx
import React from 'react';

interface ResponsiveImageProps {
  src: string;
  alt: string;
  sizes?: string;
  className?: string;
  loading?: 'lazy' | 'eager';
}

export const ResponsiveImage: React.FC<ResponsiveImageProps> = ({
  src,
  alt,
  sizes = '100vw',
  className,
  loading = 'lazy',
}) => {
  const baseUrl = process.env.REACT_APP_CDN_URL || '';
  const filename = src.replace(/\.[^.]+$/, '');
  const widths = [320, 640, 960, 1280, 1920];

  const srcSetWebP = widths
    .map((w) => `${baseUrl}${filename}-${w}w.webp ${w}w`)
    .join(', ');

  const srcSetAvif = widths
    .map((w) => `${baseUrl}${filename}-${w}w.avif ${w}w`)
    .join(', ');

  const srcSetJpg = widths
    .map((w) => `${baseUrl}${filename}-${w}w.jpg ${w}w`)
    .join(', ');

  return (
    <picture>
      {/* AVIF - Best compression */}
      <source type="image/avif" srcSet={srcSetAvif} sizes={sizes} />

      {/* WebP - Good compression, wider support */}
      <source type="image/webp" srcSet={srcSetWebP} sizes={sizes} />

      {/* JPEG - Fallback for older browsers */}
      <img
        src={`${baseUrl}${filename}-960w.jpg`}
        srcSet={srcSetJpg}
        sizes={sizes}
        alt={alt}
        className={className}
        loading={loading}
      />
    </picture>
  );
};
```

### Cache Invalidation Script

```javascript
// scripts/invalidate-cdn.js
const AWS = require('aws-sdk');
const cloudfront = new AWS.CloudFront();

const DISTRIBUTION_ID = process.env.CLOUDFRONT_DISTRIBUTION_ID;

async function invalidateCDN(paths = ['/*']) {
  const params = {
    DistributionId: DISTRIBUTION_ID,
    InvalidationBatch: {
      CallerReference: `invalidation-${Date.now()}`,
      Paths: {
        Quantity: paths.length,
        Items: paths,
      },
    },
  };

  try {
    const result = await cloudfront.createInvalidation(params).promise();
    console.log('CDN invalidation started:', result.Invalidation.Id);
    console.log('Status:', result.Invalidation.Status);
    return result;
  } catch (error) {
    console.error('CDN invalidation failed:', error);
    throw error;
  }
}

// Usage in deployment
if (require.main === module) {
  const paths = process.argv.slice(2);
  invalidateCDN(paths.length > 0 ? paths : ['/*'])
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { invalidateCDN };
```

### Deployment Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy-cdn.yml
name: Deploy to CDN

on:
  push:
    branches:
      - main
      - production

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Optimize images
        run: npm run optimize-images

      - name: Build application
        env:
          NODE_ENV: production
          CDN_URL: ${{ secrets.CDN_URL }}
        run: npm run build

      - name: Upload to S3
        uses: jakejarvis/s3-sync-action@v0.5.1
        with:
          args: --acl public-read --follow-symlinks --delete
        env:
          AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: 'us-east-1'
          SOURCE_DIR: 'dist'

      - name: Invalidate CloudFront cache
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          CLOUDFRONT_DISTRIBUTION_ID: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }}
        run: |
          npm run invalidate-cdn

      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'CDN deployment completed'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        if: always()
```

## Testing Strategy

### Performance Testing

```javascript
// tests/performance/cdn-performance.test.js
const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');

async function testCDNPerformance(url) {
  const chrome = await chromeLauncher.launch({ chromeFlags: ['--headless'] });

  const options = {
    logLevel: 'info',
    output: 'json',
    onlyCategories: ['performance'],
    port: chrome.port,
  };

  const runnerResult = await lighthouse(url, options);

  await chrome.kill();

  const { lhr } = runnerResult;
  const performance = lhr.categories.performance.score * 100;
  const fcp = lhr.audits['first-contentful-paint'].numericValue;
  const lcp = lhr.audits['largest-contentful-paint'].numericValue;
  const ttfb = lhr.audits['server-response-time'].numericValue;

  console.log('Performance Score:', performance);
  console.log('First Contentful Paint:', fcp, 'ms');
  console.log('Largest Contentful Paint:', lcp, 'ms');
  console.log('Time to First Byte:', ttfb, 'ms');

  // Assert performance thresholds
  expect(performance).toBeGreaterThan(90);
  expect(fcp).toBeLessThan(1800);
  expect(lcp).toBeLessThan(2500);
  expect(ttfb).toBeLessThan(600);
}

describe('CDN Performance Tests', () => {
  it('should meet performance targets', async () => {
    await testCDNPerformance('https://cdn.example.com');
  }, 60000);
});
```

### Cache Testing

```javascript
// tests/integration/cdn-cache.test.js
const axios = require('axios');

describe('CDN Cache Behavior', () => {
  const CDN_URL = process.env.CDN_URL;

  it('should return immutable cache headers for static assets', async () => {
    const response = await axios.get(`${CDN_URL}/static/js/main.abc123.js`);

    expect(response.headers['cache-control']).toContain('public');
    expect(response.headers['cache-control']).toContain('max-age=31536000');
    expect(response.headers['cache-control']).toContain('immutable');
  });

  it('should return short cache for HTML files', async () => {
    const response = await axios.get(`${CDN_URL}/index.html`);

    const cacheControl = response.headers['cache-control'];
    const maxAge = parseInt(cacheControl.match(/max-age=(\d+)/)[1]);

    expect(maxAge).toBeLessThanOrEqual(3600);
  });

  it('should support Brotli compression', async () => {
    const response = await axios.get(`${CDN_URL}/static/js/main.abc123.js`, {
      headers: { 'Accept-Encoding': 'br' },
    });

    expect(response.headers['content-encoding']).toBe('br');
  });

  it('should serve WebP images when supported', async () => {
    const response = await axios.get(`${CDN_URL}/images/logo-960w.webp`, {
      headers: { 'Accept': 'image/webp' },
    });

    expect(response.headers['content-type']).toContain('image/webp');
  });
});
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| CDN service outage affecting availability | Low | Critical | Setup multi-CDN failover, maintain origin server as fallback |
| Cache invalidation issues causing stale content | Medium | High | Implement versioned URLs, automated invalidation, manual purge capability |
| Increased costs with high bandwidth usage | Medium | Medium | Monitor bandwidth usage, setup cost alerts, optimize asset sizes |
| SSL/TLS certificate expiration | Low | High | Automate certificate renewal, setup expiration monitoring |
| Geographic performance variance | Medium | Medium | Use globally distributed CDN, test from multiple regions |
| Image optimization breaking visual quality | Low | Medium | Manual QA for critical images, A/B test compression levels |

## Performance Requirements

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| TTFB (Time to First Byte) | < 200ms | Lighthouse, WebPageTest |
| First Contentful Paint | < 1.5s | Core Web Vitals, Lighthouse |
| Largest Contentful Paint | < 2.5s | Core Web Vitals monitoring |
| Cache hit ratio | > 90% | CDN analytics dashboard |
| Asset load time | < 500ms | Chrome DevTools Network tab |
| Image size reduction | > 60% | Before/after file size comparison |
| Bandwidth savings | > 40% | CDN bandwidth reports |

## Security Considerations

### HTTPS Enforcement

```nginx
# Origin server nginx config
server {
    listen 80;
    server_name cdn.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name cdn.example.com;

    ssl_certificate /etc/ssl/certs/cdn.example.com.crt;
    ssl_certificate_key /etc/ssl/private/cdn.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
}
```

### Signed URLs (for protected content)

```javascript
// utils/signed-url.js
const AWS = require('aws-sdk');
const cloudFront = new AWS.CloudFront.Signer(
  process.env.CLOUDFRONT_KEY_PAIR_ID,
  process.env.CLOUDFRONT_PRIVATE_KEY
);

function getSignedUrl(url, expiresIn = 3600) {
  const expireTime = new Date().getTime() + expiresIn * 1000;

  return cloudFront.getSignedUrl({
    url,
    expires: Math.floor(expireTime / 1000),
  });
}

module.exports = { getSignedUrl };
```

### CORS Configuration

```javascript
// S3 CORS configuration
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://example.com"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3600
    }
  ]
}
```

## Error Handling

### Fallback Strategy

```javascript
// src/utils/cdn-fallback.js
const CDN_URL = process.env.REACT_APP_CDN_URL;
const ORIGIN_URL = process.env.REACT_APP_ORIGIN_URL;

export function getAssetUrl(path, useFallback = true) {
  const cdnUrl = `${CDN_URL}${path}`;

  if (!useFallback) {
    return cdnUrl;
  }

  // Return URL with fallback
  return {
    primary: cdnUrl,
    fallback: `${ORIGIN_URL}${path}`,
  };
}

// Usage in component
function ImageWithFallback({ src, alt }) {
  const [imgSrc, setImgSrc] = useState(getAssetUrl(src).primary);

  const handleError = () => {
    console.warn(`CDN failed for ${src}, using fallback`);
    setImgSrc(getAssetUrl(src).fallback);
  };

  return <img src={imgSrc} alt={alt} onError={handleError} />;
}
```

### Error Monitoring

```javascript
// monitoring/cdn-errors.js
function logCDNError(error, resource) {
  // Send to monitoring service
  fetch('/api/monitoring/cdn-error', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      resource,
      error: error.message,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
    }),
  });
}

// Global error handler for resource loading
window.addEventListener('error', (event) => {
  if (event.target.tagName === 'IMG' || event.target.tagName === 'SCRIPT') {
    const resource = event.target.src;
    if (resource.includes(CDN_URL)) {
      logCDNError(new Error('Resource load failed'), resource);
    }
  }
}, true);
```

## Progress

**0% - Not started**

## Notes

### Dependencies
- AWS SDK or Cloudflare SDK
- sharp (image optimization)
- compression-webpack-plugin
- lighthouse (performance testing)

### Best Practices

1. **Asset Organization**
   - Use content hashing for cache busting
   - Organize assets by type (js, css, images)
   - Implement versioning strategy
   - Maintain CDN URL configuration separately

2. **Cache Strategy**
   - Immutable cache for hashed assets (1 year)
   - Short cache for HTML files (5 minutes)
   - Moderate cache for API responses (if applicable)
   - Use ETags for validation

3. **Image Optimization**
   - Serve modern formats (AVIF, WebP) with JPEG fallback
   - Generate multiple sizes for responsive images
   - Use lazy loading for below-fold images
   - Remove unnecessary metadata

4. **Monitoring**
   - Track cache hit ratios
   - Monitor geographic performance
   - Set up cost alerts
   - Track Core Web Vitals

### Cost Optimization

- Enable Brotli compression to reduce bandwidth
- Use appropriate cache TTLs to maximize hit ratio
- Monitor and optimize invalidation frequency
- Consider regional pricing tiers
- Implement smart image compression

### Rollback Plan

1. Keep origin server configured as fallback
2. Maintain ability to quickly switch DNS
3. Store previous deployment artifacts
4. Document emergency procedures
5. Test fallback regularly
