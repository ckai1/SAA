% example how to add multiple fields at once

names = cell(100, 1);
inds(1:100) = 1;
data = mat2cell(randn(100, 1), inds);

for i=1:100
    names{i} = sprintf('randn%04i', i)
end

s = cell2struct(data, names, 1)

