using ProductAPI.Models;
using ProductAPI.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using StatsdClient;

namespace ProductAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ProductRepository _repository;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(ProductRepository repository, ILogger<ProductsController> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetAll()
    {
        _logger.LogInformation("Buscando todos los productos.");
        var products = await _repository.GetAllAsync();
        return Ok(products);
    }

    [HttpGet("stats")]
    public async Task<ActionResult<object>> GetStats()
    {
        // Returns product statistics: count, average, max, min prices
        var products = (await _repository.GetAllAsync()).ToList();
        if (!products.Any())
            return Ok(new { total = 0, promedio = 0, maximo = 0, minimo = 0 });

        return Ok(new
        {
            total = products.Count,
            promedio = Math.Round(products.Average(p => p.Price), 2),
            maximo = products.Max(p => p.Price),
            minimo = products.Min(p => p.Price)
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetById(int id)
    {
        var product = await _repository.GetByIdAsync(id);
        if (product == null)
        {
            _logger.LogWarning("Producto con ID {Id} no fue encontrado.", id);
            return NotFound(new { mensaje = $"Producto con id {id} no encontrado" });
        }
        return Ok(product);
    }

    [HttpPost]
    public async Task<ActionResult<Product>> Create(Product product)
    {
        _logger.LogInformation("Creando nuevo producto con nombre: {Nombre}", product.Name);
        var created = await _repository.AddAsync(product);
        
        // Métrica customizada: Incrementar el contador de productos creados
        DogStatsd.Increment("productapi.products.created");
        
        _logger.LogInformation("Producto creado exitosamente con ID {Id}.", created.Id);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<Product>> Update(int id, Product product)
    {
        _logger.LogInformation("Actualizando producto con ID {Id}.", id);
        var updated = await _repository.UpdateAsync(id, product);
        if (updated == null)
        {
            _logger.LogWarning("Fallo al actualizar. Producto con ID {Id} no encontrado.", id);
            return NotFound(new { mensaje = $"Producto con id {id} no encontrado" });
        }
        
        // Métrica customizada: Registrar la actualización
        DogStatsd.Increment("productapi.products.updated");
        
        return Ok(updated);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await _repository.DeleteAsync(id);
        if (!result)
            return NotFound(new { mensaje = $"Producto con id {id} no encontrado" });
        return NoContent();
    }
}
