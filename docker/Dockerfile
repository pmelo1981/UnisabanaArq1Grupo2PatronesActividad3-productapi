# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["src/ProductAPI/ProductAPI.csproj", "src/ProductAPI/"]
RUN dotnet restore "src/ProductAPI/ProductAPI.csproj"
COPY . .
RUN dotnet build "src/ProductAPI/ProductAPI.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "src/ProductAPI/ProductAPI.csproj" -c Release -o /app/publish

# Stage 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Install Datadog .NET Tracer
RUN apt-get update && apt-get install -y curl \
    && mkdir -p /opt/datadog \
    && curl -L https://github.com/DataDog/dd-trace-dotnet/releases/latest/download/dd-trace-linux-x64.tar.gz -o datadog.tar.gz \
    && tar xzf datadog.tar.gz -C /opt/datadog \
    && rm datadog.tar.gz

# Set Datadog Environment Variables
ENV CORECLR_ENABLE_PROFILING=1
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_DOTNET_TRACER_HOME=/opt/datadog

COPY --from=publish /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "ProductAPI.dll"]
