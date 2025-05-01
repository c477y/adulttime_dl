# Contributing to XXXDownload

## Development Setup

1. Install the required Ruby version specified in `.ruby-version`
2. Clone the repository and run `bundle install`
3. Run the test suite with `bundle exec rspec`

## Adding a New Site

Use the generator to create new site downloaders:

```shell
./exe/generate SiteName --short-name=site_name [--supports-streaming] [--supports-download]
```

### Generator Options

- `SiteName`: CamelCase name of the site (e.g., `NewSensations`)
- `--short-name`: Command-line name for the site (e.g., `newsensations`)
- `--supports-streaming`: Enable if site uses HLS streaming (default: false)
- `--supports-download`: Enable if site supports direct downloads (default:
  true)

The generator creates:

- Index class for site navigation
- Download links handler (if `--supports-download`)
- Streaming links handler (if `--supports-streaming`)
- Refresh class for fetching download links on demand (useful if download links
  have an expiration time)
- Test files

## Development Guidelines

### Testing

- Write specs for all new features
- Use VCR cassettes for HTTP interactions
- Run tests with environment variables:

  ```shell
  LOG_LEVEL=extra bundle exec rspec
  ```

### Best Practices

1. Sort supported sites alphabetically in:
   - `lib/xxx_download/contract/download_filters_contract.rb`
   - `lib/xxx_download/data/config.rb`

2. Document all public methods and classes

3. Error Handling:
   - Use appropriate error classes
   - Add meaningful error messages
   - Handle network failures gracefully

4. Configuration:
   - Update config.rb for new site-specific settings
   - Document new configuration options

5. Session Management:
   - Implement proper cookie handling
   - Add session refresh logic if required
   - Handle authentication failures

## Pull Request Process

1. Create a feature branch
2. Add tests for new functionality
3. Ensure all tests pass
4. Update documentation
5. Submit PR with clear description of changes

## Debugging Tips

- Use `--log-level=extra` for detailed logs
- Test both streaming and download modes if applicable

## Common Issues

1. **Cookie Issues**
   - Ensure proper cookie format (Netscape)
