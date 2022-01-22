using Microsoft.Extensions.Options;

namespace MasterVolumeSync.Helper;

public interface IWritableOptions<out T> : IOptionsSnapshot<T> where T : class, new()
{
    void Update(Action<T> applyChanges);
}
